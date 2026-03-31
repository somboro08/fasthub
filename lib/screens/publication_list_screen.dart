import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/publication_cubit.dart';
import '../models/publication_model.dart';
import '../theme/theme.dart';
import '../widgets/social_interaction_bar.dart';

class PublicationListScreen extends StatelessWidget {
  const PublicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publications', style: GoogleFonts.poppins()),
      ),
      body: BlocBuilder<PublicationCubit, PublicationState>(
        builder: (context, state) {
          if (state is PublicationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PublicationLoaded) {
            if (state.publications.isEmpty) {
              return const Center(
                child: Text('Aucune publication pour le moment.',
                    style: TextStyle(color: Colors.white)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.publications.length,
              itemBuilder: (context, index) {
                final publication = state.publications[index];
                return _buildPublicationCard(context, publication);
              },
            );
          } else if (state is PublicationError) {
            return Center(
              child: Text(
                'Erreur: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPublicationCard(BuildContext context, PublicationModel publication) {
    return Card(
      color: FastHubTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showPublicationDetails(context, publication),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(publication.authorAvatarUrl),
                    radius: 20,
                    onBackgroundImageError: (_, __) {},
                    child: const Icon(Icons.person, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publication.authorName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${publication.authorFiliere} - ${publication.authorLevel}',
                          style: GoogleFonts.poppins(
                            color: FastHubTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(publication.authorStatus),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      publication.authorStatus,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                publication.content,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (publication.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      publication.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  ),
                  const SizedBox(height: 12),
                  SocialInteractionBar(
                  targetId: publication.id,
                  targetType: 'publication',
                  ),
                  const SizedBox(height: 12),
                  Align(                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(publication.publishedAt),
                  style: GoogleFonts.poppins(
                    color: FastHubTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPublicationDetails(BuildContext context, PublicationModel publication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: FastHubTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(publication.authorAvatarUrl),
                            radius: 25,
                            onBackgroundImageError: (_, __) {},
                            child: const Icon(Icons.person, size: 25),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  publication.authorName,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${publication.authorFiliere} - ${publication.authorLevel}',
                                  style: GoogleFonts.poppins(
                                    color: FastHubTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getBadgeColor(publication.authorStatus),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              publication.authorStatus,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(publication.publishedAt),
                        style: GoogleFonts.poppins(
                          color: FastHubTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(color: Colors.white30, height: 30),
                      Text(
                        publication.content,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SocialInteractionBar(
                        targetId: publication.id,
                        targetType: 'publication',
                      ),
                      const SizedBox(height: 16),
                      if (publication.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              publication.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[800],
                                child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FastHubTheme.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'cam':
        return Colors.green;
      case 'res':
        return Colors.orange;
      case 'bue':
        return Colors.purple;
      case 'prof':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
