import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/social_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../theme/theme.dart';
import 'comment_section.dart';

class SocialInteractionBar extends StatelessWidget {
  final String targetId;
  final String targetType;
  final bool showCommentButton;

  const SocialInteractionBar({
    super.key,
    required this.targetId,
    required this.targetType,
    this.showCommentButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : null;

    // Load interactions when the bar is built
    context.read<SocialCubit>().loadInteractions(targetId, targetType, userId);

    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        final isLiked = state.isLiked[targetId] ?? false;
        final likesCount = state.likesCount[targetId] ?? 0;
        final commentsCount = state.comments[targetId]?.length ?? 0;

        return Row(
          children: [
            // Like Button
            _buildActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: '$likesCount',
              color: isLiked ? Colors.red : Colors.white70,
              onTap: () {
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter pour liker.')),
                  );
                  return;
                }
                context.read<SocialCubit>().toggleLike(
                  userId: userId,
                  targetId: targetId,
                  targetType: targetType,
                );
              },
            ),
            const SizedBox(width: 16),
            // Comment Button
            if (showCommentButton)
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: '$commentsCount',
                color: Colors.white70,
                onTap: () {
                  _showComments(context);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSection(
        targetId: targetId,
        targetType: targetType,
      ),
    );
  }
}
