import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fasthub/screens/student_registration/student_step3_screen.dart'; // Import the next screen

class StudentStep2Screen extends StatefulWidget {
  final String selectedStudentOption;

  const StudentStep2Screen({super.key, required this.selectedStudentOption});

  @override
  State<StudentStep2Screen> createState() => _StudentStep2ScreenState();
}

class _StudentStep2ScreenState extends State<StudentStep2Screen> {
  String? _selectedFaculty;
  String? _selectedField;
  String? _selectedLevel; // L1, L2, L3, M1, M2

  final List<String> _faculties = ['FAST', 'FLSH', 'FSEG']; // Example faculties
  final Map<String, List<String>> _fields = {
    'FAST': ['MIA', 'PC', 'CBG'],
    'FLSH': ['Lettres Modernes', 'Histoire'], // Example fields
    'FSEG': ['Économie', 'Gestion'],
  };
  final List<String> _levels = ['L1', 'L2', 'L3', 'M1', 'M2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Étudiant - Étape 2', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sélectionnez votre faculté, filière et niveau :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Faculté',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: _selectedFaculty,
              items: _faculties.map((faculty) {
                return DropdownMenuItem(
                  value: faculty,
                  child: Text(faculty, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFaculty = newValue;
                  _selectedField = null; // Reset field when faculty changes
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filière',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: _selectedField,
              items: _selectedFaculty == null
                  ? []
                  : _fields[_selectedFaculty!]!.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(field, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedField = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Niveau (L1, L2, L3, M1, M2)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: _selectedLevel,
              items: _levels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLevel = newValue;
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedFaculty == null || _selectedField == null || _selectedLevel == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentStep3Screen(
                            selectedStudentOption: widget.selectedStudentOption,
                            faculty: _selectedFaculty!,
                            field: _selectedField!,
                            level: _selectedLevel!,
                          ),
                        ),
                      );
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