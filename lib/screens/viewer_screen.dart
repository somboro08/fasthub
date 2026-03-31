import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'; // For HTML preview
import 'package:url_launcher/url_launcher.dart'; // For launching PDF URLs
import '../models/document_model.dart';
import '../theme/theme.dart';

class ViewerScreen extends StatelessWidget {
  final DocumentModel document;
  // isOffline flag is less relevant now as content dictates display.
  // We can decide to remove it or use it for specific offline UI indicators.

  const ViewerScreen({super.key, required this.document}); // Removed isOffline from constructor

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: Text(document.title),
        backgroundColor: FastHubTheme.surfaceColor,
        actions: [
          if (document.pdfPath != null && document.pdfPath!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _launchUrl(document.pdfPath!),
              tooltip: 'Ouvrir le PDF',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: FastHubTheme.textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Auteur: ${document.authorId} - Filière: ${document.filiere}',
              style: TextStyle(color: FastHubTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: document.previewHtml.isNotEmpty
                  ? SingleChildScrollView(
                      child: HtmlWidget(
                        document.previewHtml,
                        textStyle: const TextStyle(color: FastHubTheme.textColor),
                        // You can customize styling further here
                        // For example:
                        // customStylesBuilder: (element) {
                        //   if (element.localName == 'h1') {
                        //     return {'color': 'white', 'font-size': '2em'};
                        //   }
                        //   return null;
                        // },
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        document.content, // Fallback to raw content if no HTML preview
                        style: const TextStyle(color: FastHubTheme.textColor),
                      ),
                    ),
            ),
            // if (isOffline) // Removed this condition, can be added back with specific logic
            //   Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(color: FastHubTheme.surfaceColor, borderRadius: BorderRadius.circular(8)),
            //     child: const Text('Document hors ligne', style: TextStyle(color: Colors.amber)),
            //   )
          ],
        ),
      ),
    );
  }
}
