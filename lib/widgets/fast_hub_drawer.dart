import 'package:flutter/material.dart';
import '../theme/theme.dart';

class FastHubDrawer extends StatelessWidget {
  const FastHubDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: FastHubTheme.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(gradient: FastHubTheme.primaryGradient),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
                const SizedBox(height: 8),
                Text('Utilisateur', style: FastHubTheme.appTitleStyle.copyWith(fontSize: 18)),
                Text('filiere@example.com', style: TextStyle(color: FastHubTheme.textSecondary)),
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.white),
              title: const Text('Accueil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded, color: Colors.white),
              title: const Text('Mes documents', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.white),
              title: const Text('Favoris', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white54),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.white),
              title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white),
              title: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
