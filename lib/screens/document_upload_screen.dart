import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../bloc/auth_cubit.dart';
import '../services/document_service.dart';
import '../theme/theme.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? _selectedFile;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _uuid = const Uuid();

  String? _selectedFiliere;
  String? _selectedLevel;
  String? _selectedMatiere;
  String? _selectedAcademicYear;
  String? _selectedDocumentType;
  
  final _customFiliereController = TextEditingController();
  final _customMatiereController = TextEditingController();
  final _customDocumentTypeController = TextEditingController();
  final _documentOriginController = TextEditingController();

  // Data sources for dropdowns
  List<String> _filieres = ['MIA', 'PC', 'CBG'];
  List<String> _levels = ['L1', 'L2', 'L3', 'M1', 'M2'];
  List<String> _matieres = ['Mathématiques', 'Physique', 'Informatique', 'Chimie', 'Biologie'];
  List<String> _documentTypes = ['Examen (Session Normale)', 'Examen (Rattrapage)', 'TD', 'Cours', 'Fiche', 'Mémoire'];
  late List<String> _academicYears;

  @override
  void initState() {
    super.initState();
    _academicYears = List.generate(5, (index) {
      final year = DateTime.now().year - index;
      return '${year - 1}-$year';
    });
    _selectedAcademicYear = _academicYears.first;
    _loadDynamicData();
  }

  Future<void> _loadDynamicData() async {
    try {
      final service = DocumentService(Supabase.instance.client);
      final dynamicFilieres = await service.getUniqueFilieres();
      final dynamicSubjects = await service.getUniqueSubjects();
      final dynamicTypes = await service.getUniqueDocumentTypes();

      setState(() {
        for (var f in dynamicFilieres) {
          if (!_filieres.contains(f)) _filieres.add(f);
        }
        for (var s in dynamicSubjects) {
          if (!_matieres.contains(s)) _matieres.add(s);
        }
        for (var t in dynamicTypes) {
          if (!_documentTypes.contains(t)) _documentTypes.add(t);
        }
        if (!_filieres.contains('Autre...')) _filieres.add('Autre...');
        if (!_matieres.contains('Autre...')) _matieres.add('Autre...');
        if (!_documentTypes.contains('Autre...')) _documentTypes.add('Autre...');
      });
    } catch (e) {
      print('Error loading dynamic data: $e');
    }
  }

  @override
  void dispose() {
    _customFiliereController.dispose();
    _customMatiereController.dispose();
    _customDocumentTypeController.dispose();
    _documentOriginController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? FastHubTheme.errorColor : FastHubTheme.primaryColor,
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
      });
      _showSnackBar('Fichier sélectionné: ${result.files.first.name}');
    } else {
      _showSnackBar('Sélection de fichier annulée.');
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedFile == null) {
      _showSnackBar('Veuillez sélectionner un fichier à téléverser.', isError: true);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnackBar('Veuillez vous connecter pour téléverser un fichier.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String fileName = _selectedFile!.path.split('/').last;
      final String userId = authState.user.id;
      const String bucketName = 'document-pdfs';
      final String docId = _uuid.v4();
      final String supabasePath = '$userId/$docId-$fileName';

      await Supabase.instance.client.storage
          .from(bucketName)
          .upload(supabasePath, _selectedFile!);

      final String publicUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(supabasePath);

      final finalFiliere = _selectedFiliere == 'Autre...' ? _customFiliereController.text.trim() : _selectedFiliere;
      final finalMatiere = _selectedMatiere == 'Autre...' ? _customMatiereController.text.trim() : _selectedMatiere;
      final finalType = _selectedDocumentType == 'Autre...' ? _customDocumentTypeController.text.trim() : _selectedDocumentType;

      await Supabase.instance.client.from('documents').insert({
        'id': docId,
        'title': fileName,
        'author_id': userId,
        'filiere': finalFiliere,
        'level': _selectedLevel,
        'subject': finalMatiere,
        'document_type': finalType,
        'document_origin': _documentOriginController.text.trim(),
        'academic_year': _selectedAcademicYear,
        'pdf_path': publicUrl,
        'content': '', // No LaTeX content for direct uploads
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_public': true,
      });

      _showSnackBar('Fichier téléversé et informations enregistrées !');
      if (mounted) {
        Navigator.of(context).pop(true); // Pop with true on success
      }
    } catch (e) {
      _showSnackBar('Échec du téléversement: $e', isError: true);
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FastHubTheme.accentColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      style: const TextStyle(color: FastHubTheme.textColor),
      validator: required
          ? (val) => (val == null || val.isEmpty) ? 'Ce champ est requis.' : null
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FastHubTheme.accentColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      style: const TextStyle(color: FastHubTheme.textColor),
      dropdownColor: FastHubTheme.surfaceColor,
      validator: (val) => val == null ? 'Veuillez sélectionner une option.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Téléverser un document'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectedFile == null ? 'Sélectionner un fichier' : 'Fichier: ${_selectedFile!.path.split('/').last}',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              _buildDropdown(
                label: 'Filière',
                value: _selectedFiliere,
                items: _filieres,
                onChanged: (value) => setState(() => _selectedFiliere = value),
                icon: Icons.school,
              ),
              if (_selectedFiliere == 'Autre...') ...[
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _customFiliereController,
                  label: 'Nom de la nouvelle filière',
                  icon: Icons.add_home_work,
                ),
              ],
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Niveau',
                value: _selectedLevel,
                items: _levels,
                onChanged: (value) => setState(() => _selectedLevel = value),
                icon: Icons.grade,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Matière',
                value: _selectedMatiere,
                items: _matieres,
                onChanged: (value) => setState(() => _selectedMatiere = value),
                icon: Icons.book,
              ),
              if (_selectedMatiere == 'Autre...') ...[
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _customMatiereController,
                  label: 'Nom de la nouvelle matière',
                  icon: Icons.add_box,
                ),
              ],
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Type de document',
                value: _selectedDocumentType,
                items: _documentTypes,
                onChanged: (value) => setState(() => _selectedDocumentType = value),
                icon: Icons.category,
              ),
              if (_selectedDocumentType == 'Autre...') ...[
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _customDocumentTypeController,
                  label: 'Précisez le type',
                  icon: Icons.edit_note,
                ),
              ],
              const SizedBox(height: 16),
              _buildTextField(
                controller: _documentOriginController,
                label: 'Origine / Responsable (Optionnel)',
                icon: Icons.person_outline,
                required: false,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Année Académique',
                value: _selectedAcademicYear,
                items: _academicYears,
                onChanged: (value) => setState(() => _selectedAcademicYear = value),
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Téléverser',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
