import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/social_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../models/comment_model.dart';
import '../theme/theme.dart';
import 'social_interaction_bar.dart';

class CommentSection extends StatefulWidget {
  final String targetId;
  final String targetType;

  const CommentSection({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentCtrl = TextEditingController();
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submitComment() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    if (_commentCtrl.text.trim().isEmpty) return;

    String authorName = 'Utilisateur';
    final profile = authState.profile;
    if (profile != null) {
      final name = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
      if (name.isNotEmpty) authorName = name;
    } else if (authState.user.email != null) {
      authorName = authState.user.email!.split('@')[0];
    }

    context.read<SocialCubit>().addComment(
      targetId: widget.targetId,
      targetType: widget.targetType,
      authorId: authState.user.id,
      authorName: authorName,
      authorAvatarUrl: authState.profile?.avatarUrl,
      content: _commentCtrl.text.trim(),
      parentId: _replyingTo?.id,
    );

    _commentCtrl.clear();
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: FastHubTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Commentaires', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: BlocBuilder<SocialCubit, SocialState>(
              builder: (context, state) {
                final allComments = state.comments[widget.targetId] ?? [];
                final rootComments = allComments.where((c) => c.parentId == null).toList();

                if (rootComments.isEmpty) {
                  return Center(child: Text('Soyez le premier à commenter !', style: GoogleFonts.poppins(color: Colors.white60)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rootComments.length,
                  itemBuilder: (context, index) {
                    final comment = rootComments[index];
                    final replies = allComments.where((c) => c.parentId == comment.id).toList();
                    return _buildCommentItem(comment, replies: replies);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment, {List<CommentModel> replies = const [], bool isReply = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isReply ? 32.0 : 0.0, top: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 15 : 20,
                backgroundImage: comment.authorAvatarUrl != null ? NetworkImage(comment.authorAvatarUrl!) : null,
                child: comment.authorAvatarUrl == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.authorName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(comment.content, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(DateFormat('dd/MM HH:mm').format(comment.createdAt), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                        const SizedBox(width: 16),
                        // Likes on comment
                        SocialInteractionBar(targetId: comment.id, targetType: 'comment', showCommentButton: false),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingTo = comment;
                            });
                          },
                          child: Text('Répondre', style: GoogleFonts.poppins(color: FastHubTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (replies.isNotEmpty)
          ...replies.map((reply) => _buildCommentItem(reply, isReply: true)).toList(),
      ],
    );
  }

  Widget _buildInputArea() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black26,
        child: const Text('Veuillez vous connecter pour commenter.', style: TextStyle(color: Colors.white70)),
      );
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(color: FastHubTheme.surfaceColor, border: const Border(top: BorderSide(color: Colors.white12))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white10,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('En réponse à ${_replyingTo!.authorName}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
                  IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.grey), onPressed: () => setState(() => _replyingTo = null)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Votre commentaire...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: FastHubTheme.accentColor,
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _submitComment),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
