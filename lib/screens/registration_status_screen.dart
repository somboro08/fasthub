import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fasthub/screens/student_registration/student_step1_screen.dart'; // Future student registration screen
import 'package:fasthub/screens/admin_registration/admin_step1_screen.dart'; // Future admin registration screen

enum UserType { etudiant, administration }

class RegistrationStatusScreen extends StatefulWidget {
  const RegistrationStatusScreen({super.key});

  @override
  State<RegistrationStatusScreen> createState() => _RegistrationStatusScreenState();
}

class _RegistrationStatusScreenState extends State<RegistrationStatusScreen> {
  UserType? _selectedUserType; // Nullable to indicate no selection initially

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choisissez votre statut',
          style: GoogleFonts.poppins(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Bienvenue!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildUserTypeOption(
              UserType.etudiant,
              'Étudiant',
              'Je suis un étudiant qui cherche à accéder aux ressources académiques.',
            ),
            const SizedBox(height: 20),
            _buildUserTypeOption(
              UserType.administration,
              'Administration',
              'Je fais partie du corps enseignant ou administratif de l université.',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedUserType == null
                  ? null // Disable button if no type is selected
                  : () {
                      if (_selectedUserType == UserType.etudiant) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentStep1Screen()));
                      } else if (_selectedUserType == UserType.administration) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminStep1Screen()));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Suivant',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(UserType type, String title, String description) {
    final isSelected = _selectedUserType == type;
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserType = type;
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}