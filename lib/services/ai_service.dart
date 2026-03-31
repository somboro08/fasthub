import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_chat_model.dart';

class AIService {
  final _supabase = Supabase.instance.client;

  Future<String> callGeminiProxy(String prompt) async {
    try {
      final response = await _supabase.functions.invoke(
        'gemini-proxy',
        body: {'prompt': prompt},
      );
      
      if (response.status != 200) {
        throw Exception("Erreur Edge Function: ${response.status}");
      }

      // Structure typique de réponse Gemini (à adapter selon votre proxy)
      final data = response.data;
      return data['candidates'][0]['content']['parts'][0]['text'];
    } catch (e) {
      throw Exception("Erreur lors de l'appel à l'IA via le proxy: $e");
    }
  }

  Future<List<AIChatSession>> getSessions(String userId) async {
    final response = await _supabase
        .from('ai_sessions')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    
    return (response as List).map((json) => AIChatSession.fromJson(json)).toList();
  }

  Future<AIChatSession> createSession(String userId, String title) async {
    final response = await _supabase
        .from('ai_sessions')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single();
    
    return AIChatSession.fromJson(response);
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _supabase
        .from('ai_sessions')
        .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    await _supabase.from('ai_sessions').delete().eq('id', sessionId);
  }

  Future<List<AIChatMessage>> getMessages(String sessionId) async {
    final response = await _supabase
        .from('ai_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => AIChatMessage.fromJson(json)).toList();
  }

  Future<AIChatMessage> saveMessage({
    required String sessionId,
    required String role,
    required String content,
  }) async {
    final response = await _supabase
        .from('ai_messages')
        .insert({
          'session_id': sessionId,
          'role': role,
          'content': content,
        })
        .select()
        .single();
    
    // Update session's updated_at
    await _supabase
        .from('ai_sessions')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);

    return AIChatMessage.fromJson(response);
  }
}
