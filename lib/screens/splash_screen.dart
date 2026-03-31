import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(255, 75, 52, 74), FastHubTheme.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
                child: Image.asset(
                  'assets/images/fasthublogo.jpg',
                  width: 150, // Adjust size as needed
                  height: 150, // Adjust size as needed
                ),
              ),
              const SizedBox(height: 24),
              Text('FastHub', style: FastHubTheme.appTitleStyle.copyWith(fontSize: 36)),
              const SizedBox(height: 8),
              Text('Biblotheque de la fast', style: TextStyle(color: FastHubTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
