import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/social_cubit.dart';
import '../models/comment_model.dart';
import '../theme/theme.dart';
import '../bloc/auth_cubit.dart';

class CommentBottomSheet extends StatefulWidget {
  final String targetId;
  final String targetType;

  const CommentBottomSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<SocialCubit>().addComment(
            targetId: widget.targetId,
            targetType: widget.targetType,
            authorId: authState.user.id,
            authorName: '${authState.profile?.firstName ?? ''} ${authState.profile?.lastName ?? ''}',
            authorAvatarUrl: authState.profile?.avatarUrl,
            content: _commentController.text.trim(),
            parentId: _replyToId,
          );
      _commentController.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour commenter.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: FastHubTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Commentaires',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.grey),
          Flexible(
            child: BlocBuilder<SocialCubit, SocialState>(
              builder: (context, state) {
                final comments = state.comments[widget.targetId] ?? [];
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Aucun commentaire pour le moment.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // Organize comments into parent and children
                final parentComments = comments.where((c) => c.parentId == null).toList();
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: parentComments.length,
                  itemBuilder: (context, index) {
                    final comment = parentComments[index];
                    final replies = comments.where((c) => c.parentId == comment.id).toList();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentItem(
                          comment: comment,
                          onReply: () {
                            setState(() {
                              _replyToId = comment.id;
                              _replyToName = comment.authorName;
                            });
                          },
                        ),
                        ...replies.map((reply) => Padding(
                          padding: const EdgeInsets.only(left: 48.0),
                          child: _CommentItem(
                            comment: reply,
                            isReply: true,
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyToName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  Text(
                    'En réponse à $_replyToName',
                    style: TextStyle(color: FastHubTheme.accentColor, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToId = null;
                      _replyToName = null;
                    }),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon: Icon(Icons.send, color: FastHubTheme.accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentItem({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundImage: NetworkImage(comment.authorAvatarUrl ?? 'https://cdn.icon-icons.com/icons2/1378/PNG/512/avatardefault_92824.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM HH:mm').format(comment.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (!isReply)
                  GestureDetector(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Répondre',
                        style: TextStyle(
                          color: FastHubTheme.accentColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
