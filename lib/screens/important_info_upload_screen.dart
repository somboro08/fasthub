import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/important_info_cubit.dart';
import '../theme/theme.dart';

class ImportantInfoUploadScreen extends StatefulWidget {
  const ImportantInfoUploadScreen({super.key});

  @override
  State<ImportantInfoUploadScreen> createState() => _ImportantInfoUploadScreenState();
}

class _ImportantInfoUploadScreenState extends State<ImportantInfoUploadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _addImportantInfo() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir le titre et le contenu.', isError: true);
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnackBar('Veuillez vous connecter pour ajouter des informations importantes.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<ImportantInfoCubit>().addImportantInfo(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            authorId: authState.user.id,
            authorProfile: authState.profile,
          );
      _showSnackBar('Information importante ajoutée avec succès !');
      if (mounted) {
        Navigator.of(context).pop(true); // Pop with true on success
      }
    } catch (e) {
      _showSnackBar("Échec de l'ajout de l'information importante: ${e.toString()}", isError: true);
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
        title: Text('Nouvelle Information Importante', style: GoogleFonts.poppins()),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: BlocListener<ImportantInfoCubit, ImportantInfoState>(
        listener: (context, state) {
          if (state is ImportantInfoError) {
            _showSnackBar(state.message, isError: true);
            setState(() { _isLoading = false; });
          } else if (state is ImportantInfoLoading && !state.toString().contains('Loaded')) {
             setState(() { _isLoading = true; });
          } else if (state is ImportantInfoLoaded) {
             setState(() { _isLoading = false; });
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Titre de l'information",
                  hintStyle: TextStyle(color: FastHubTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: const TextStyle(color: FastHubTheme.textColor),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: "Contenu de l'information",
                  hintStyle: TextStyle(color: FastHubTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: const TextStyle(color: FastHubTheme.textColor),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _addImportantInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FastHubTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Ajouter l'information",
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
