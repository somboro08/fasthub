import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/document_cubit.dart';
import '../models/profile_model.dart';
import '../theme/theme.dart';
import '../widgets/document_card.dart';
import '../models/document_model.dart'; // Import DocumentModel
import 'package:intl/intl.dart'; // For date formatting

// For document opening logic (similar to HomeScreen)
import 'editor_screen.dart';
import 'pdf_viewer_page.dart';

class UserDetailScreen extends StatefulWidget {
  final Profile userProfile;

  const UserDetailScreen({super.key, required this.userProfile});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? FastHubTheme.errorColor : FastHubTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Document opening logic (copied from HomeScreen, adapted)
  Widget _buildDocumentList(List<DocumentModel> documents, {String emptyMessage = 'Aucun document trouvé.'}) {
    if (documents.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: TextStyle(color: FastHubTheme.textSecondary, fontSize: 16)),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Important for nested ListView
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return DocumentCard(
          document: doc,
          onTap: () {
            if (doc.pdfPath != null && (doc.pdfPath!.startsWith('http') || doc.pdfPath!.endsWith('.pdf'))) {
              // Open PDF from network URL or local path
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(path: doc.pdfPath!, title: doc.title),
                ),
              );
            } else if (doc.content.isNotEmpty) {
              // Open LaTeX document in EditorScreen for editing
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditorScreen(document: doc),
                ),
              );
            } else {
              // Fallback for other file types or if content/pdfPath is missing
              _showSnackBar('Impossible d\'ouvrir ce type de document.', isError: true);
            }
          },
          // onSaveOffline not needed here directly, as it's the author's documents
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Load documents published by this user
    context.read<DocumentCubit>().loadDocumentsByAuthor(widget.userProfile.id);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;
    final userEmail = (context.read<AuthCubit>().state is Authenticated)
        ? (context.read<AuthCubit>().state as Authenticated).user.email
        : 'N/A'; // Assuming we need current user's email for comparison

    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: Text(profile.matricule ?? 'Profil Utilisateur'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 80,
              backgroundColor: FastHubTheme.accentColor.withOpacity(0.2),
              backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                  ? NetworkImage(profile.avatarUrl!) as ImageProvider
                  : null,
              child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: FastHubTheme.accentColor,
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              profile.matricule ?? 'Utilisateur Inconnu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (userEmail != 'N/A') // Only show email if available (e.g., current user's own detail page)
              Text(
                'Email: $userEmail',
                style: TextStyle(color: FastHubTheme.textSecondary, fontSize: 16),
              ),
            const SizedBox(height: 8),
            if (profile.filiere != null && profile.filiere!.isNotEmpty)
              Text(
                'Filière: ${profile.filiere}',
                style: TextStyle(color: FastHubTheme.textSecondary, fontSize: 16),
              ),
            const SizedBox(height: 8),
            if (profile.niveauEtude != null && profile.niveauEtude!.isNotEmpty)
              Text(
                'Niveau d\'étude: ${profile.niveauEtude}',
                style: TextStyle(color: FastHubTheme.textSecondary, fontSize: 16),
              ),
            const Divider(height: 30, color: FastHubTheme.textSecondary),
            Text(
              'Documents Publiés',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
            ),
            BlocConsumer<DocumentCubit, DocumentState>(
              listener: (context, state) {
                if (state is DocumentError) {
                  _showSnackBar(state.message, isError: true);
                }
              },
              builder: (context, state) {
                if (state is DocumentLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DocumentsLoaded) {
                  return _buildDocumentList(state.documents, emptyMessage: 'Aucun document publié par cet utilisateur.');
                } else if (state is DocumentError) {
                  return Center(child: Text('Erreur: ${state.message}', style: TextStyle(color: FastHubTheme.errorColor)));
                }
                return const SizedBox.shrink(); // Fallback for other states
              },
            ),
          ],
        ),
      ),
    );
  }
}
