import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/comment_model.dart';
import '../services/social_service.dart';

// --- States ---
class SocialState {
  final Map<String, int> likesCount; // targetId -> count
  final Map<String, bool> isLiked; // targetId -> bool
  final Map<String, List<CommentModel>> comments; // targetId -> list
  final bool isLoading;
  final String? error;

  SocialState({
    this.likesCount = const {},
    this.isLiked = const {},
    this.comments = const {},
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    Map<String, int>? likesCount,
    Map<String, bool>? isLiked,
    Map<String, List<CommentModel>>? comments,
    bool? isLoading,
    String? error,
  }) {
    return SocialState(
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// --- Cubit ---
class SocialCubit extends Cubit<SocialState> {
  final SocialService _socialService;
  final _uuid = const Uuid();

  SocialCubit(this._socialService) : super(SocialState());

  Future<void> loadInteractions(String targetId, String targetType, String? userId) async {
    try {
      final count = await _socialService.getLikesCount(targetId, targetType);
      final comments = await _socialService.getComments(targetId, targetType);
      bool liked = false;
      if (userId != null) {
        liked = await _socialService.isLiked(userId, targetId, targetType);
      }

      emit(state.copyWith(
        likesCount: Map.of(state.likesCount)..[targetId] = count,
        isLiked: Map.of(state.isLiked)..[targetId] = liked,
        comments: Map.of(state.comments)..[targetId] = comments,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> toggleLike({
    required String userId,
    required String targetId,
    required String targetType,
  }) async {
    final currentLiked = state.isLiked[targetId] ?? false;
    final currentCount = state.likesCount[targetId] ?? 0;

    // Optimistic update
    emit(state.copyWith(
      isLiked: Map.of(state.isLiked)..[targetId] = !currentLiked,
      likesCount: Map.of(state.likesCount)..[targetId] = !currentLiked ? currentCount + 1 : currentCount - 1,
    ));

    try {
      await _socialService.toggleLike(userId, targetId, targetType);
    } catch (e) {
      // Revert on error
      emit(state.copyWith(
        isLiked: Map.of(state.isLiked)..[targetId] = currentLiked,
        likesCount: Map.of(state.likesCount)..[targetId] = currentCount,
        error: e.toString(),
      ));
    }
  }

  Future<void> addComment({
    required String targetId,
    required String targetType,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
    String? parentId,
  }) async {
    final newComment = CommentModel(
      id: _uuid.v4(),
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      createdAt: DateTime.now(),
      targetId: targetId,
      targetType: targetType,
      parentId: parentId,
    );

    // Optimistic update
    final currentComments = List<CommentModel>.from(state.comments[targetId] ?? []);
    emit(state.copyWith(
      comments: Map.of(state.comments)..[targetId] = [...currentComments, newComment],
    ));

    try {
      await _socialService.addComment(newComment);
      final comments = await _socialService.getComments(targetId, targetType);
      emit(state.copyWith(
        comments: Map.of(state.comments)..[targetId] = comments,
      ));
    } catch (e) {
      // Revert
      emit(state.copyWith(
        comments: Map.of(state.comments)..[targetId] = currentComments,
        error: e.toString(),
      ));
    }
  }
}
