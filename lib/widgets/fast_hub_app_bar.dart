import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FastHubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final Widget? leadingWidget; // New parameter for custom leading widget

  const FastHubAppBar({
    super.key,
    this.title = 'FastHub',
    this.actions,
    this.showBackButton = false,
    this.onMenuPressed,
    this.leadingWidget, // Initialize new parameter
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leadingWidget ?? // Use leadingWidget if provided
          (showBackButton
              ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context))
              : (onMenuPressed != null // Only show menu if onMenuPressed is provided
                  ? IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28), onPressed: onMenuPressed)
                  : null // If no leadingWidget and no back/menu, then no leading widget
                )
          ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: FastHubTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color.fromARGB(255, 37, 36, 40).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make row only as wide as its children
          children: [
            Image.asset(
              'assets/images/fasthublogo.jpg',
              height: 24, // Adjust size as needed
              width: 24,
            ),
            const SizedBox(width: 8), // Spacing between logo and text
            Text(title, style: FastHubTheme.appTitleStyle.copyWith(fontSize: 14)),
          ],
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }
}
