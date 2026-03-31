import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';
import '../theme/theme.dart';
import 'dart:io';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onSaveOffline; // Added callback

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onSaveOffline, // Added to constructor
  });

  bool _isImage(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.gif') ||
        lowerPath.endsWith('.webp');
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'examen':
        return Icons.quiz_outlined;
      case 'cours':
        return Icons.menu_book_outlined;
      case 'td':
        return Icons.assignment_outlined;
      case 'fiche':
        return Icons.note_outlined;
      case 'memoire':
        return Icons.school_outlined;
      case 'polycope':
        return Icons.library_books_outlined;
      case 'rapport':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getIconColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'examen':
        return Colors.redAccent;
      case 'cours':
        return Colors.blueAccent;
      case 'td':
        return Colors.greenAccent;
      case 'polycope':
        return Colors.orangeAccent;
      default:
        return FastHubTheme.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImageThumbnail = document.pdfPath != null && _isImage(document.pdfPath!);
    final iconColor = _getIconColor(document.documentType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: FastHubTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Icon Section
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black26,
                      iconColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: hasImageThumbnail
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: document.pdfPath!.startsWith('http')
                            ? Image.network(document.pdfPath!, fit: BoxFit.cover)
                            : Image.file(File(document.pdfPath!), fit: BoxFit.cover),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _getIconForType(document.documentType),
                            size: 40,
                            color: iconColor,
                          ),
                          Positioned(
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (document.documentType ?? 'DOC').toUpperCase(),
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 12),
              // Content Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.subject,
                      style: TextStyle(
                        color: FastHubTheme.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 12,
                          color: FastHubTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filière: ${document.filiere}',
                          style: TextStyle(
                            color: FastHubTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: FastHubTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(document.updatedAt),
                          style: TextStyle(
                            color: FastHubTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (onSaveOffline != null)
                          IconButton(
                            icon: Icon(Icons.download_for_offline, color: FastHubTheme.accentColor, size: 20),
                            onPressed: onSaveOffline,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
