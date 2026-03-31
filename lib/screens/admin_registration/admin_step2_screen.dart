import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fasthub/screens/admin_registration/admin_step3_screen.dart'; // Import the next screen

class AdminStep2Screen extends StatefulWidget {
  final String selectedAdminOption;
  final String? otherRole; // Only if selectedAdminOption is 'Autre'

  const AdminStep2Screen({
    super.key,
    required this.selectedAdminOption,
    this.otherRole,
  });

  @override
  State<AdminStep2Screen> createState() => _AdminStep2ScreenState();
}

class _AdminStep2ScreenState extends State<AdminStep2Screen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teachingDomainController = TextEditingController();
  final List<TextEditingController> _taughtSubjectsControllers = [];

  @override
  void initState() {
    super.initState();
    _addSubjectField(); // Add initial subject field
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _teachingDomainController.dispose();
    for (var controller in _taughtSubjectsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubjectField() {
    setState(() {
      _taughtSubjectsControllers.add(TextEditingController());
    });
  }

  bool _isFormValid() {
    bool baseValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty;

    if (widget.selectedAdminOption == 'Enseignant') {
      baseValid = baseValid && _teachingDomainController.text.isNotEmpty;
      bool subjectsValid = _taughtSubjectsControllers.any((controller) => controller.text.isNotEmpty);
      baseValid = baseValid && subjectsValid;
    }
    return baseValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription Administration - Étape 2', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Informations personnelles et professionnelles :',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.selectedAdminOption == 'Enseignant') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _teachingDomainController,
                decoration: InputDecoration(
                  labelText: 'Domaine d enseignement',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.poppins(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Text(
                'Matières enseignées:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ..._taughtSubjectsControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                TextEditingController controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Matière ${idx + 1}',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          style: GoogleFonts.poppins(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_taughtSubjectsControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _taughtSubjectsControllers.removeAt(idx);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addSubjectField,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une matière'),
                ),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isFormValid()
                  ? () {
                      List<String> taughtSubjects = _taughtSubjectsControllers
                          .map((c) => c.text)
                          .where((text) => text.isNotEmpty)
                          .toList();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminStep3Screen(
                            selectedAdminOption: widget.selectedAdminOption,
                            otherRole: widget.otherRole,
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            teachingDomain: _teachingDomainController.text,
                            taughtSubjects: taughtSubjects,
                          ),
                        ),
                      );
                    }
                  : null,
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