import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../theme/theme.dart';

class PasswordDisplayScreen extends StatelessWidget {
  final String generatedPassword;

  const PasswordDisplayScreen({super.key, required this.generatedPassword});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Mot de Passe Généré", style: GoogleFonts.poppins()),
        backgroundColor: FastHubTheme.surfaceColor,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Inscription Réussie!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Votre mot de passe temporaire a été généré. Veuillez le copier et l'utiliser pour vous connecter.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: FastHubTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: FastHubTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FastHubTheme.accentColor),
                ),
                child: Text(
                  generatedPassword,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text("Copier le mot de passe"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: generatedPassword));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mot de passe copié dans le presse-papiers!"),
                      backgroundColor: FastHubTheme.successColor,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: FastHubTheme.accentColor.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "Aller à la page de connexion",
                  style: TextStyle(color: FastHubTheme.accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
