import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/ai_chat_model.dart';
import '../services/ai_service.dart';
import '../models/profile_model.dart';

abstract class AIChatState extends Equatable {
  const AIChatState();
  @override
  List<Object?> get props => [];
}

class AIChatInitial extends AIChatState {}

class AIChatLoading extends AIChatState {}

class AIChatSessionsLoaded extends AIChatState {
  final List<AIChatSession> sessions;
  final AIChatSession? currentSession;
  final List<AIChatMessage> messages;
  final bool isSending;

  const AIChatSessionsLoaded({
    required this.sessions,
    this.currentSession,
    this.messages = const [],
    this.isSending = false,
  });

  AIChatSessionsLoaded copyWith({
    List<AIChatSession>? sessions,
    AIChatSession? currentSession,
    List<AIChatMessage>? messages,
    bool? isSending,
  }) {
    return AIChatSessionsLoaded(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [sessions, currentSession, messages, isSending];
}

class AIChatError extends AIChatState {
  final String message;
  const AIChatError(this.message);
  @override
  List<Object?> get props => [message];
}

class AIChatCubit extends Cubit<AIChatState> {
  final AIService _aiService;
  final Profile? profile;

  AIChatCubit({
    required AIService aiService,
    String? apiKey,
    this.profile,
  })  : _aiService = aiService,
        super(AIChatInitial());

  Future<void> loadSessions(String userId) async {
    emit(AIChatLoading());
    try {
      final sessions = await _aiService.getSessions(userId);
      emit(AIChatSessionsLoaded(sessions: sessions));
    } catch (e) {
      emit(AIChatError(e.toString()));
    }
  }

  Future<void> selectSession(AIChatSession session) async {
    final currentState = state;
    if (currentState is AIChatSessionsLoaded) {
      emit(currentState.copyWith(isSending: true));
      try {
        final messages = await _aiService.getMessages(session.id);
        emit(currentState.copyWith(
          currentSession: session,
          messages: messages,
          isSending: false,
        ));
      } catch (e) {
        emit(AIChatError(e.toString()));
      }
    }
  }

  Future<void> createNewSession(String userId, String firstMessage) async {
    final currentState = state;
    List<AIChatSession> sessions = [];
    if (currentState is AIChatSessionsLoaded) {
      sessions = currentState.sessions;
    }

    emit(AIChatLoading());
    try {
      final title = firstMessage.length > 30 ? firstMessage.substring(0, 30) + "..." : firstMessage;
      final session = await _aiService.createSession(userId, title);
      final updatedSessions = [session, ...sessions];
      
      emit(AIChatSessionsLoaded(
        sessions: updatedSessions,
        currentSession: session,
        messages: const [],
      ));

      await sendMessage(firstMessage);
    } catch (e) {
      emit(AIChatError(e.toString()));
    }
  }

  Future<void> sendMessage(String text) async {
    final currentState = state;
    if (currentState is! AIChatSessionsLoaded || currentState.currentSession == null) return;

    final session = currentState.currentSession!;
    
    try {
      final userMessage = await _aiService.saveMessage(
        sessionId: session.id,
        role: 'user',
        content: text,
      );

      emit(currentState.copyWith(
        messages: [...currentState.messages, userMessage],
        isSending: true,
      ));

      // Build context for AI
      String contextText = "Tu es FastHub AI, l'assistant intelligent de la plateforme FastHub pour les étudiants de la FAST (Faculté des Sciences et Techniques). ";
      if (profile != null) {
        contextText += "Tu t'adresses à un(e) étudiant(e) nommé(e) ${profile!.firstName} ${profile!.lastName} en filière ${profile!.filiere} (niveau ${profile!.level}). ";
      }
      contextText += "Réponds de manière concise, précise et utilise le format LaTeX pour les formules mathématiques et scientifiques (entoure-les de \$ pour inline et \$\$ pour display). ";
      contextText += "Si l'utilisateur demande de générer un PDF, inclus un bloc de code LaTeX complet (\\documentclass...\\end{document}).";
      
      final prompt = "$contextText\n\nQuestion de l'étudiant: $text";
      
      final responseText = await _aiService.callGeminiProxy(prompt);

      final modelMessage = await _aiService.saveMessage(
        sessionId: session.id,
        role: 'model',
        content: responseText,
      );

      emit(currentState.copyWith(
        messages: [...currentState.messages, userMessage, modelMessage],
        isSending: false,
      ));
    } catch (e) {
      emit(AIChatError(e.toString()));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final currentState = state;
    if (currentState is AIChatSessionsLoaded) {
      try {
        await _aiService.deleteSession(sessionId);
        final updatedSessions = currentState.sessions.where((s) => s.id != sessionId).toList();
        
        if (currentState.currentSession?.id == sessionId) {
          emit(AIChatSessionsLoaded(sessions: updatedSessions));
        } else {
          emit(currentState.copyWith(sessions: updatedSessions));
        }
      } catch (e) {
        emit(AIChatError(e.toString()));
      }
    }
  }
}
