import 'package:fasthub/screens/student_registration/student_step2_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentStep1Screen extends StatefulWidget {
  const StudentStep1Screen({super.key});

  @override
  State<StudentStep1Screen> createState() => _StudentStep1ScreenState();
}

class _StudentStep1ScreenState extends State<StudentStep1Screen> {
  // Define options for student status
  final List<String> _studentOptions = [
    'Étudiant simple',
    'Responsable d amphi',
    'Membre BUE (Président, Secrétaire, Vice-président)',
  ];

  String? _selectedStudentOption; // To hold the selected option

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Étudiant - Étape 1', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sélectionnez votre statut étudiant :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Loop through options to create radio buttons
            ..._studentOptions.map((option) {
              return RadioListTile<String>(
                title: Text(option, style: GoogleFonts.poppins(fontSize: 16)),
                value: option,
                groupValue: _selectedStudentOption,
                onChanged: (String? value) {
                  setState(() {
                    _selectedStudentOption = value;
                  });
                },
              );
            }).toList(),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedStudentOption == null
                  ? null // Disable if no option is selected
                  : () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudentStep2Screen(selectedStudentOption: _selectedStudentOption!)));
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
}
