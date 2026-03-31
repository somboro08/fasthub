import 'package:fasthub/screens/admin_registration/admin_step2_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminStep1Screen extends StatefulWidget {
  const AdminStep1Screen({super.key});

  @override
  State<AdminStep1Screen> createState() => _AdminStep1ScreenState();
}

class _AdminStep1ScreenState extends State<AdminStep1Screen> {
  final List<String> _adminOptions = [
    'Enseignant',
    'Autre',
  ];
  String? _selectedAdminOption;
  final TextEditingController _otherRoleController = TextEditingController();
  bool _showOtherRoleField = false;

  @override
  void dispose() {
    _otherRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Administration - Étape 1', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Sélectionnez votre statut administratif :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            ..._adminOptions.map((option) {
              return RadioListTile<String>(
                title: Text(option, style: GoogleFonts.poppins(fontSize: 16)),
                value: option,
                groupValue: _selectedAdminOption,
                onChanged: (String? value) {
                  setState(() {
                    _selectedAdminOption = value;
                    _showOtherRoleField = (value == 'Autre');
                  });
                },
              );
            }).toList(),
            if (_showOtherRoleField) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otherRoleController,
                decoration: InputDecoration(
                  labelText: 'Veuillez spécifier votre rôle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedAdminOption == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminStep2Screen(
                            selectedAdminOption: _selectedAdminOption!,
                            otherRole: _showOtherRoleField ? _otherRoleController.text : null,
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
