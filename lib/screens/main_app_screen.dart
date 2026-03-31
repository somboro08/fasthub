import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../theme/theme.dart';
import '../widgets/fast_hub_drawer.dart';
import 'package:fasthub/screens/document_upload_screen.dart'; // Import the new screen

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [HomeScreen(), SizedBox(), SizedBox()];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('FastHub'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [ // Added actions
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
              );
            },
            tooltip: 'Téléverser un nouveau document',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: FastHubTheme.surfaceColor,
        selectedItemColor: FastHubTheme.primaryLight,
        unselectedItemColor: FastHubTheme.textSecondary,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Recherche'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
      drawer: const FastHubDrawer(),
    );
  }
}