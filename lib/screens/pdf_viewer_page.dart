import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io'; // Required for File

class PdfViewerPage extends StatelessWidget {
  final String path; // Can be a URL or a local file path
  final String title;

  const PdfViewerPage({super.key, required this.path, this.title = 'Document PDF'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: path.startsWith('http')
          ? SfPdfViewer.network(path)
          : SfPdfViewer.file(File(path)),
    );
  }
}