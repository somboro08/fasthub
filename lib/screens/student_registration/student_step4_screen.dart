import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fasthub/services/auth_service.dart';
import 'package:fasthub/screens/password_display_screen.dart';
import '../../theme/theme.dart';

class StudentStep4Screen extends StatefulWidget {
  final String selectedStudentOption;
  final String faculty;
  final String field;
  final String level;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String matricule;
  final String phone;
  final String email;

  const StudentStep4Screen({
    super.key,
    required this.selectedStudentOption,
    required this.faculty,
    required this.field,
    required this.level,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.matricule,
    required this.phone,
    required this.email,
  });

  @override
  State<StudentStep4Screen> createState() => _StudentStep4ScreenState();
}

class _StudentStep4ScreenState extends State<StudentStep4Screen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registerStudent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Generate a random 6-digit password
    final String generatedPassword = (100000 + Random().nextInt(900000)).toString();

    try {
      final AuthService authService = AuthService(Supabase.instance.client);
      final profileData = {
        'email': widget.email,
        'first_name': widget.firstName,
        'last_name': widget.lastName,
        'user_type': 'student',
        'phone': widget.phone,
        'matricule': widget.matricule,
        'date_of_birth': widget.dateOfBirth.toIso8601String(),
        'student_option': widget.selectedStudentOption,
        'faculty': widget.faculty,
        'filiere': widget.field,
        'level': widget.level,
      };

      final response = await authService.signUp(
        email: widget.email,
        password: generatedPassword,
        data: profileData,
      );

      if (mounted) {
        // Show success dialog about email confirmation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: FastHubTheme.surfaceColor,
            title: Text('Inscription réussie', style: GoogleFonts.poppins(color: Colors.white)),
            content: Text(
              'Un email de confirmation a été envoyé à ${widget.email}. Veuillez confirmer votre email avant de vous connecter.\n\nVotre mot de passe généré est: $generatedPassword\n\nNotez-le bien !',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => PasswordDisplayScreen(generatedPassword: generatedPassword),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Étudiant - Étape 4', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Confirmation des informations',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Veuillez vérifier vos informations ci-dessous. Un mot de passe sera généré automatiquement pour vous à la fin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            Card(
              color: FastHubTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Nom Complet:', '${widget.firstName} ${widget.lastName}'),
                    _buildInfoRow('Email:', widget.email),
                    _buildInfoRow('Matricule:', widget.matricule),
                    _buildInfoRow('Filière:', '${widget.faculty} - ${widget.field} - ${widget.level}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _registerStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Terminer l'inscription",
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: FastHubTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
