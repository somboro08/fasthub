import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/publication_cubit.dart';
import '../theme/theme.dart';

class PublicationUploadScreen extends StatefulWidget {
  const PublicationUploadScreen({super.key});

  @override
  State<PublicationUploadScreen> createState() => _PublicationUploadScreenState();
}

class _PublicationUploadScreenState extends State<PublicationUploadScreen> {
  final _contentController = TextEditingController();
  File? _selectedImageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addPublication() async {
    if (_contentController.text.trim().isEmpty && _selectedImageFile == null) {
      _showSnackBar('Veuillez écrire quelque chose ou ajouter une image.', isError: true);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnackBar('Veuillez vous connecter pour publier.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<PublicationCubit>().addPublication(
            content: _contentController.text.trim(),
            imageFile: _selectedImageFile,
            authorId: authState.user.id,
            authorProfile: authState.profile,
          );
      _showSnackBar('Publication ajoutée avec succès !');
      if (mounted) {
        Navigator.of(context).pop(true); // Pop with true on success
      }
    } catch (e) {
      _showSnackBar("Échec de l'ajout de la publication: ${e.toString()}", isError: true);
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
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Nouvelle Publication', style: GoogleFonts.poppins()),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: BlocListener<PublicationCubit, PublicationState>(
        listener: (context, state) {
          if (state is PublicationError) {
            _showSnackBar(state.message, isError: true);
            setState(() { _isLoading = false; });
          } else if (state is PublicationLoading && !state.toString().contains('Loaded')) { // Avoid showing loading for subsequent reloads after add
            setState(() { _isLoading = true; });
          } else if (state is PublicationLoaded) {
             setState(() { _isLoading = false; });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Que voulez-vous partager ?',
                  hintStyle: TextStyle(color: FastHubTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: const TextStyle(color: FastHubTheme.textColor),
              ),
              const SizedBox(height: 20),
              _selectedImageFile != null
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(_selectedImageFile!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedImageFile = null;
                            });
                          },
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Ajouter une image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _addPublication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Publier',
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
