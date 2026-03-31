import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fasthub/bloc/document_cubit.dart';
import 'package:fasthub/models/document_model.dart';
import 'package:fasthub/widgets/document_card.dart';
import 'package:fasthub/screens/pdf_viewer_page.dart';
import 'package:fasthub/screens/editor_screen.dart';
import 'package:fasthub/bloc/auth_cubit.dart';
import 'package:http/http.dart' as http; // Added for downloading PDFs
import 'package:path_provider/path_provider.dart'; // Added for saving files locally
import 'dart:io'; // Import for File
import 'package:fasthub/services/database_service.dart'; // Import FastHubDatabase

class DocumentListPage extends StatefulWidget {
  final String filiereName;

  const DocumentListPage({super.key, required this.filiereName});

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  String? _selectedLicenseLevel;
  String? _selectedMatiere;
  String? _selectedType;
  late List<String> _academicYears; // Will be generated
  String? _selectedAcademicYear;

  final List<String> _licenseLevels = ['L1', 'L2', 'L3', 'M1', 'M2'];
  final List<String> _matieres = ['Mathématiques', 'Physique', 'Informatique', 'Chimie', 'Biologie']; // Example
 final List<String> _types = ['Polycopes', 'TD', 'Examens', 'Rapports'];
 


  @override
  void initState() {
    super.initState();
    // Generate academic years for the last 5 years
    _academicYears = List.generate(
      5,
      (index) {
        final year = DateTime.now().year - index;
        return '$year-${year + 1}';
      },
    );
    _selectedAcademicYear = _academicYears.first; // Default to the current academic year

    _loadDocuments();
  }

  void _loadDocuments() {
    context.read<DocumentCubit>().loadAllPublicDocumentsForFiliere(
      widget.filiereName,
      level: _selectedLicenseLevel,
      subject: _selectedMatiere,
      academicYear: _selectedAcademicYear,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveDocumentOffline(DocumentModel document) async {
    _showSnackBar('Téléchargement du PDF "${document.title}" pour utilisation hors ligne...', isError: false);
    try {
      if (document.pdfPath != null && document.pdfPath!.startsWith('http')) {
        // Handle PDF download and save
        final response = await http.get(Uri.parse(document.pdfPath!));
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${document.id}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Update document with local path and mark as offline
        final localDoc = document.copyWith(pdfPath: filePath, isOffline: true);
        await FastHubDatabase.instance.insertDocument(localDoc);
      } else if (document.content.isNotEmpty) {
        // Handle LaTeX content saving (already present in document model)
        final localDoc = document.copyWith(isOffline: true);
        await FastHubDatabase.instance.insertDocument(localDoc);
      } else {
        _showSnackBar('Ce document ne peut pas être enregistré hors ligne.', isError: true);
        return;
      }
      _showSnackBar('"${document.title}" enregistré hors ligne !');
    } catch (e) {
      _showSnackBar('Échec de l\'enregistrement hors ligne: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filiereName, style: GoogleFonts.poppins()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu actions (e.g., sort, filter options)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Licence',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    value: _selectedLicenseLevel,
                    items: _licenseLevels.map((level) {
                      return DropdownMenuItem(value: level, child: Text(level, style: GoogleFonts.poppins()));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLicenseLevel = newValue;
                        _loadDocuments();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Matière',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    value: _selectedMatiere,
                    items: _matieres.map((matiere) {
                      return DropdownMenuItem(value: matiere, child: Text(matiere, style: GoogleFonts.poppins()));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMatiere = newValue;
                        _loadDocuments();
                      });
                    },
                  ),
                ),
                 Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Types',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    value: _selectedType,
                    items: _types.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type, style: GoogleFonts.poppins()));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue;
                        _loadDocuments();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Academic Years Tabs
          SizedBox(
            height: 40, // Adjust height as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _academicYears.length,
              itemBuilder: (context, index) {
                final year = _academicYears[index];
                final isSelected = _selectedAcademicYear == year;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(year, style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    onSelected: (selected) {
                      setState(() {
                        _selectedAcademicYear = selected ? year : null;
                        _loadDocuments();
                      });
                    },
                    backgroundColor: Colors.blueGrey.shade700,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<DocumentCubit, DocumentState>(
              listener: (context, state) {
                if (state is DocumentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is DocumentLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DocumentsLoaded) {
                  List<DocumentModel> documents = state.documents; // Documents are already filtered by service

                  if (documents.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun document trouvé pour cette filière et ces critères.',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return DocumentCard(
                        document: doc,
                        onTap: () {
                          if (doc.pdfPath != null && (doc.pdfPath!.startsWith('http') || doc.pdfPath!.endsWith('.pdf'))) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerPage(path: doc.pdfPath!, title: doc.title),
                              ),
                            );
                          } else if (doc.content.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditorScreen(document: doc),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impossible d\'ouvrir ce type de document.')),
                            );
                          }
                        },
                        onSaveOffline: () => _saveDocumentOffline(doc),
                      );
                    },
                  );
                } else if (state is DocumentError) {
                  return Center(
                    child: Text(
                      'Erreur: ${state.message}',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator()); // Fallback
              },
            ),
          ),
        ],
      ),
    );
  }
}
