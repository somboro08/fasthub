import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: FastHubTheme.surfaceColor,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Général',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30, color: FastHubTheme.textSecondary),
                  ListTile(
                    title: Text('Thème Sombre', style: TextStyle(color: FastHubTheme.textColor)),
                    trailing: Switch(
                      value: true, // TODO: Link to ThemeCubit
                      onChanged: (value) {
                        // TODO: Implement theme change logic via ThemeCubit
                      },
                      activeColor: FastHubTheme.accentColor,
                    ),
                  ),
                  ListTile(
                    title: Text('Notifications', style: TextStyle(color: FastHubTheme.textColor)),
                    trailing: Switch(
                      value: false, // TODO: Link to actual setting
                      onChanged: (value) {
                        // TODO: Implement notification setting logic
                      },
                      activeColor: FastHubTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: FastHubTheme.surfaceColor,
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Données',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30, color: FastHubTheme.textSecondary),
                  ListTile(
                    title: Text('Synchroniser maintenant', style: TextStyle(color: FastHubTheme.textColor)),
                    trailing: Icon(Icons.sync, color: FastHubTheme.accentColor),
                    onTap: () {
                      // TODO: Implement manual sync trigger
                      print('Trigger manual sync');
                    },
                  ),
                  ListTile(
                    title: Text('Effacer les données locales', style: TextStyle(color: FastHubTheme.errorColor)),
                    trailing: Icon(Icons.delete_forever, color: FastHubTheme.errorColor),
                    onTap: () {
                      // TODO: Implement local data clearing
                      print('Clear local data');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
