import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/important_info_cubit.dart';
import '../models/important_info_model.dart';
import '../theme/theme.dart';
import '../widgets/social_interaction_bar.dart';

class ImportantInfoListScreen extends StatelessWidget {
  const ImportantInfoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informations importantes', style: GoogleFonts.poppins()),
      ),
      body: BlocBuilder<ImportantInfoCubit, ImportantInfoState>(
        builder: (context, state) {
          if (state is ImportantInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ImportantInfoLoaded) {
            if (state.infos.isEmpty) {
              return const Center(
                child: Text('Aucune information importante pour le moment.',
                    style: TextStyle(color: Colors.white)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.infos.length,
              itemBuilder: (context, index) {
                final info = state.infos[index];
                return _buildInfoCard(context, info);
              },
            );
          } else if (state is ImportantInfoError) {
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

  Widget _buildInfoCard(BuildContext context, ImportantInfoModel info) {
    return Card(
      color: FastHubTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showImportantInfoDetails(context, info),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Par ${info.author}',
                    style: GoogleFonts.poppins(
                      color: FastHubTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(info.publishedAt),
                    style: GoogleFonts.poppins(
                      color: FastHubTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                info.content,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SocialInteractionBar(
                targetId: info.id,
                targetType: 'important_info',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportantInfoDetails(BuildContext context, ImportantInfoModel info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: FastHubTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  info.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Par ${info.author} - ${DateFormat('dd/MM/yyyy HH:mm').format(info.publishedAt)}',
                  style: GoogleFonts.poppins(
                    color: FastHubTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const Divider(color: Colors.white30, height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.content,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SocialInteractionBar(
                          targetId: info.id,
                          targetType: 'important_info',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
