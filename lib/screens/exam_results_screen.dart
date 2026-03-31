import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart'; // Assuming you have a theme file

class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  String? _selectedStudyYear;
  String? _selectedFiliere;
  String? _selectedAcademicYear;
  bool _isCatchUpSession = false; // Normal or Catch-up session

  final List<String> _studyYears = ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'];
  final List<String> _filieres = ['MIA', 'PC', 'CBG']; // Example filieres
  final List<String> _academicYears = ['2025-2026', '2024-2025', '2023-2024']; // Example academic years

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats', style: GoogleFonts.poppins()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu actions (e.g., export, refresh)
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 26, 31, 42), Color.fromARGB(255, 37, 36, 46)],
          ),
        ),
        child: Column(
          children: [
            // Filters Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Année d étude',
                            labelStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          isDense: true,
                          value: _selectedStudyYear,
                          items: _studyYears.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStudyYear = newValue;
                              // TODO: Filter results
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Filière',
                            labelStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          isDense: true,
                          value: _selectedFiliere,
                          items: _filieres.map((filiere) {
                            return DropdownMenuItem(
                              value: filiere,
                              child: Text(filiere, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedFiliere = newValue;
                              // TODO: Filter results
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Année scolaire',
                            labelStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          isDense: true,
                          value: _selectedAcademicYear,
                          items: _academicYears.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year, style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAcademicYear = newValue;
                              // TODO: Filter results
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Session de rattrapage',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                            ),
                            Switch(
                              value: _isCatchUpSession,
                              onChanged: (bool newValue) {
                                setState(() {
                                  _isCatchUpSession = newValue;
                                  // TODO: Filter results
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Student Results and Statistics Section
            Expanded(
              child: DefaultTabController(
                length: 3, // Example: 3 students, will be dynamic
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Matricule 1 - Nom A'),
                        Tab(text: 'Matricule 2 - Nom B'),
                        Tab(text: 'Matricule 3 - Nom C'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildStudentResultCard('Matricule 1 - Nom A'),
                          _buildStudentResultCard('Matricule 2 - Nom B'),
                          _buildStudentResultCard('Matricule 3 - Nom C'),
                        ],
                      ),
                    ),
                    // Statistics Summary
                    _buildStatisticsSummary(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentResultCard(String studentName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: FastHubTheme.surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Divider(color: Colors.white30),
              // Header for results table
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('Matière (Code, Crédits)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white70)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('Note', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white70), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
              // Example results (will be dynamic)
              _buildSubjectResultRow('Programmation Avancée', 'PA301', 5, 15.5),
              _buildEcuesSubRow('ECUE 1: Java', 8),
              _buildEcuesSubRow('ECUE 2: Python', 7.5),
              _buildSubjectResultRow('Bases de Données', 'BD302', 4, 9.0, isFailed: true),
              _buildSubjectResultRow('Réseaux Informatiques', 'RI303', 6, 12.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectResultRow(String subject, String code, int credits, double grade, {bool isFailed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$subject ($code, $credits crédits)',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              grade.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                color: isFailed ? Colors.redAccent : Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcuesSubRow(String ecueName, double grade) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 2.0, bottom: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '  - $ecueName',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              grade.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                color: grade < 10 ? Colors.redAccent.withOpacity(0.7) : Colors.lightGreenAccent.withOpacity(0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 10.0),
      color: FastHubTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de la session',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(color: Colors.white30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Matières à rattraper:', style: GoogleFonts.poppins(color: Colors.white70)),
              Text('2', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          // More stats can be added here
        ],
      ),
    );
  }
}
