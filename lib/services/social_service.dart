import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class SocialService {
  final SupabaseClient _supabaseClient;

  SocialService(this._supabaseClient);

  // --- LIKES ---

  Future<bool> isLiked(String userId, String targetId, String targetType) async {
    final response = await _supabaseClient
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('target_id', targetId)
        .eq('target_type', targetType)
        .maybeSingle();
    return response != null;
  }

  Future<int> getLikesCount(String targetId, String targetType) async {
    try {
      final response = await _supabaseClient
          .from('likes')
          .select('id')
          .eq('target_id', targetId)
          .eq('target_type', targetType);
      
      if (response is List) {
        return response.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> toggleLike(String userId, String targetId, String targetType) async {
    final liked = await isLiked(userId, targetId, targetType);
    if (liked) {
      await _supabaseClient
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('target_id', targetId)
          .eq('target_type', targetType);
    } else {
      await _supabaseClient.from('likes').insert({
        'user_id': userId,
        'target_id': targetId,
        'target_type': targetType,
      });
    }
  }

  // --- COMMENTS ---

  Future<List<CommentModel>> getComments(String targetId, String targetType) async {
    final response = await _supabaseClient
        .from('comments')
        .select()
        .eq('target_id', targetId)
        .eq('target_type', targetType)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => CommentModel.fromJson(json)).toList();
  }

  Future<void> addComment(CommentModel comment) async {
    await _supabaseClient.from('comments').insert(comment.toJson());
  }

  Future<void> deleteComment(String commentId) async {
    await _supabaseClient.from('comments').delete().eq('id', commentId);
  }
}
