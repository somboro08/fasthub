// [file name]: editor_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_cubit.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fasthub/screens/mathjax_display_screen.dart';
import '../models/document_model.dart';
import '../bloc/document_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../theme/theme.dart';
import '../services/latex_converter_service.dart';

class EditorScreen extends StatefulWidget {
  final DocumentModel? document;
  const EditorScreen({super.key, this.document});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _uuid = const Uuid();
  
  // Contrôleurs pour l'éditeur
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _lineNumbersController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();
  
  // États
  String _compiledHtml = '';
  String? _compiledPdfUrl;
  String _mathJaxHtml = '';
  bool _isLoading = false;
  bool _showLineNumbers = true;
  bool _wrapText = false;
  double _fontSize = 14.0;
  late final WebViewController _webViewController;
  
  // Snippets organisés par catégorie
  final Map<String, List<Map<String, String>>> _latexSnippets = {
    'Mathématiques': [
      {'label': 'Inline Math', 'code': '\$...\$'},
      {'label': 'Display Math', 'code': '\$\$...\$\$'},
      {'label': 'Fraction', 'code': '\\frac{numérateur}{dénominateur}'},
      {'label': 'Racine carrée', 'code': '\\sqrt{expression}'},
      {'label': 'Somme', 'code': '\\sum_{i=1}^{n} i'},
    ],
    'Structure': [
      {'label': 'Section', 'code': '\\section{Nom de la section}'},
      {'label': 'Subsection', 'code': '\\subsection{Nom de la sous-section}'},
      {'label': 'Paragraphe', 'code': '\\paragraph{Nom du paragraphe}'},
    ],
    'Listes': [
      {'label': 'Liste à puces', 'code': '\\begin{itemize}\n\\item Premier\n\\item Second\n\\end{itemize}'},
      {'label': 'Liste numérotée', 'code': '\\begin{enumerate}\n\\item Premier\n\\item Second\n\\end{enumerate}'},
    ],
    'Tableaux': [
      {'label': 'Tableau simple', 'code': '\\begin{tabular}{|c|c|}\n\\hline A & B \\\\ \\hline\nC & D \\\\ \\hline\n\\end{tabular}'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Length changed to 3

    // Pré-remplir si document existant
    if (widget.document != null) {
      _titleCtrl.text = widget.document!.title;
      _contentCtrl.text = widget.document!.content;
      _subjectCtrl.text = widget.document!.subject;
      _compiledHtml = widget.document!.previewHtml;
      _compiledPdfUrl = widget.document!.pdfPath;
    }

    // Synchroniser les scrolls (listener for _contentCtrl removed)
    _editorScrollController.addListener(() {
      if (_lineNumbersController.hasClients) {
        _lineNumbersController.jumpTo(_editorScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    // _contentCtrl.removeListener(_updateMathJaxPreview); // Removed
    _contentCtrl.dispose();
    _subjectCtrl.dispose();
    _editorScrollController.dispose();
    _lineNumbersController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }



  String _escapeHtml(String text) {
    const escapeChars = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    };
    return text.replaceAllMapped(
    RegExp(r'[&<>"]'),
      (match) => escapeChars[match.group(0)]!,
    );
  }

  // Widget pour les numéros de ligne
  Widget _buildLineNumbers(BuildContext context, int lineCount) {
    return Container(
      width: 50,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(right: BorderSide(color: Colors.grey.shade800)),
      ),
      child: ListView.builder(
        controller: _lineNumbersController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lineCount,
        itemBuilder: (context, index) {
          return Container(
            height: 24, // Hauteur fixe pour correspondre à la ligne
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: _fontSize * 0.9,
                fontFamily: 'Monaco, Consolas, "Courier New", monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  // Insertion de snippets LaTeX
  void _insertLatexSnippet(String snippet) {
    final text = _contentCtrl.text;
    final selection = _contentCtrl.selection;
    
    // Sécurité pour éviter l'erreur RangeError
    if (selection.start < 0) return;
    if (selection.start > text.length) return;
    if (selection.end < 0) return;
    if (selection.end > text.length) return;
    
    // Si on a du texte sélectionné, on le remplace
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      snippet = snippet.replaceFirst('...', selectedText);
    }
    
    // Insérer le snippet
    final newText = text.replaceRange(selection.start, selection.end, snippet);
    _contentCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + snippet.length,
        affinity: TextAffinity.downstream,
      ),
    );
    
    // Remettre le focus sur l'éditeur
    _editorFocusNode.requestFocus();
  }

  // Menu déroulant pour les catégories de snippets
  Widget _buildSnippetDropdown() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add_box, color: FastHubTheme.textColor),
      tooltip: 'Insérer un snippet LaTeX',
      onSelected: (String category) {
        _showSnippetDialog(category);
      },
      itemBuilder: (BuildContext context) {
        return _latexSnippets.keys.map((String category) {
          return PopupMenuItem<String>(
            value: category,
            child: Text(category, style: TextStyle(color: FastHubTheme.textColor)),
          );
        }).toList();
      },
    );
  }

  // Dialog pour choisir un snippet dans une catégorie
  void _showSnippetDialog(String category) {
    final snippets = _latexSnippets[category]!;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: FastHubTheme.surfaceColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Snippets - $category',
                    style: TextStyle(
                      color: FastHubTheme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: snippets.length,
                    itemBuilder: (context, index) {
                      final snippet = snippets[index];
                      return Card(
                        color: FastHubTheme.backgroundColor,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(
                            snippet['label']!,
                            style: TextStyle(color: FastHubTheme.textColor),
                          ),
                          subtitle: Text(
                            snippet['code']!,
                            style: TextStyle(
                              color: FastHubTheme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Monaco, Consolas, "Courier New", monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.content_copy,
                            color: FastHubTheme.accentColor,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _insertLatexSnippet(snippet['code']!);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer', style: TextStyle(color: FastHubTheme.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Barre d'outils de l'éditeur simplifiée
  Widget _buildEditorToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: FastHubTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Snippets
            _buildSnippetDropdown(),
            const SizedBox(width: 8),
            
            // Séparateur
            Container(width: 1, height: 20, color: FastHubTheme.dividerColor),
            const SizedBox(width: 8),
            
            // Taille de police
            IconButton(
              icon: Icon(Icons.text_decrease, color: FastHubTheme.textColor, size: 20),
              onPressed: () {
                setState(() {
                  if (_fontSize > 10) _fontSize -= 1;
                });
              },
              tooltip: 'Réduire la taille',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('${_fontSize.toInt()}px', 
                  style: TextStyle(color: FastHubTheme.textColor, fontSize: 12)),
            ),
            IconButton(
              icon: Icon(Icons.text_increase, color: FastHubTheme.textColor, size: 20),
              onPressed: () {
                setState(() {
                  if (_fontSize < 24) _fontSize += 1;
                });
              },
              tooltip: 'Augmenter la taille',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
            
            const SizedBox(width: 8),
            
            // Options d'affichage
            IconButton(
              icon: Icon(
                _showLineNumbers ? Icons.list_alt : Icons.list,
                color: _showLineNumbers ? FastHubTheme.accentColor : FastHubTheme.textColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showLineNumbers = !_showLineNumbers;
                });
              },
              tooltip: 'Numéros de ligne',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
            
            const SizedBox(width: 8),
            
            // Actions de texte
            IconButton(
              icon: Icon(Icons.format_bold, color: FastHubTheme.textColor, size: 20),
              onPressed: () => _insertLatexSnippet('\\textbf{...}'),
              tooltip: 'Gras',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
            IconButton(
              icon: Icon(Icons.format_italic, color: FastHubTheme.textColor, size: 20),
              onPressed: () => _insertLatexSnippet('\\textit{...}'),
              tooltip: 'Italique',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
          ],
        ),
      ),
    );
  }

  // Éditeur LaTeX corrigé
  Widget _buildLatexEditor() {
    final lineCount = _contentCtrl.text.split('\n').length;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéros de ligne
          if (_showLineNumbers && lineCount > 0) 
            _buildLineNumbers(context, lineCount),
          
          // Éditeur principal avec focus
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              focusNode: _editorFocusNode,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: FastHubTheme.textColor,
                fontSize: _fontSize,
                fontFamily: 'Monaco, Consolas, "Courier New", monospace',
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: 'Commencez à taper votre LaTeX ici...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              cursorColor: FastHubTheme.accentColor,
              cursorWidth: 2.0,
              scrollController: _editorScrollController,
              scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }

  // Indicateur de syntaxe LaTeX
  Widget _buildSyntaxInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FastHubTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: FastHubTheme.accentColor, size: 18),
              const SizedBox(width: 8),
              Text('Syntaxe LaTeX rapide', 
                  style: TextStyle(
                    color: FastHubTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildSyntaxBadge('\$...\$', 'Math inline'),
              _buildSyntaxBadge('\$\$...\$\$', 'Math display'),
              _buildSyntaxBadge('\\begin{...}', 'Environnement'),
              _buildSyntaxBadge('\\section{}', 'Section'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxBadge(String code, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FastHubTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FastHubTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code, style: TextStyle(
            color: FastHubTheme.accentColor,
            fontSize: 12,
            fontFamily: 'Monaco, Consolas, "Courier New", monospace',
          )),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: FastHubTheme.textSecondary,
            fontSize: 11,
          )),
        ],
      ),
    );
  }

  // Compilation LaTeX
  Future<void> _compileLaTeX() async {
    setState(() {
      _isLoading = true;
      _compiledPdfUrl = null;
    });

    final latexContent = _contentCtrl.text;
    if (latexContent.isEmpty) {
      _showSnackBar('Veuillez entrer du contenu LaTeX à compiler.', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    const String latexliteApiKey = String.fromEnvironment('LATEXLITE_API_KEY');
    if (latexliteApiKey.isEmpty) {
      _showSnackBar('Veuillez configurer votre clé API LaTeXLite via --dart-define', isError: true);
      setState(() { _isLoading = false; });
      return;
    }

    final url = Uri.parse('https://latexlite.com/v1/renders-sync');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $latexliteApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'template': latexContent}),
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/output_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _compiledPdfUrl = filePath;
          _compiledHtml = '''
            <div style="padding: 20px; background: #1a1a1a; border-radius: 10px;">
              <h2 style="color: #3498db;">Prévisualisation du document</h2>
              <div style="background: #2d2d2d; padding: 15px; border-radius: 8px; margin-top: 10px; font-family: monospace;">
                ${_contentCtrl.text.replaceAll('\n', '<br>').replaceAll('  ', '&nbsp;&nbsp;')}
              </div>
            </div>
          ''';
        });
        _tabController.animateTo(2);
        _showSnackBar('Compilation LaTeX réussie !');
      } else {
        final errorMessage = response.body.isNotEmpty
            ? 'LaTeXLite Erreur (${response.statusCode}): ${utf8.decode(response.bodyBytes)}'
            : 'LaTeXLite Erreur (code: ${response.statusCode})';
        _showSnackBar(errorMessage, isError: true);
        setState(() { _compiledPdfUrl = null; });
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
      setState(() { _compiledPdfUrl = null; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Reste des méthodes...
  Future<String?> _showSubjectInputDialog() async {
    _subjectCtrl.clear();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: FastHubTheme.surfaceColor,
          title: Text('Matière/UE du document', style: TextStyle(color: FastHubTheme.textColor)),
          content: TextField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              hintText: 'Ex: Algèbre Linéaire, Physique Quantique',
              filled: true,
              fillColor: FastHubTheme.backgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              hintStyle: TextStyle(color: FastHubTheme.textSecondary),
            ),
            style: const TextStyle(color: FastHubTheme.textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annuler', style: TextStyle(color: FastHubTheme.textSecondary)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Enregistrer', style: TextStyle(color: FastHubTheme.accentColor)),
              onPressed: () => Navigator.of(dialogContext).pop(_subjectCtrl.text),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? FastHubTheme.errorColor : FastHubTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  Future<void> _saveDocument({required String subject, bool isPublic = false, bool isDraft = true}) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      _showSnackBar('Veuillez vous connecter pour enregistrer.', isError: true);
      return;
    }

    if (subject.trim().isEmpty) {
      _showSnackBar('Veuillez spécifier la matière/UE.', isError: true);
      return;
    }

    final now = DateTime.now();
    final docId = _uuid.v4();
    String? finalPdfPath = _compiledPdfUrl;

    if (_compiledPdfUrl != null && authState.user.id.isNotEmpty) {
      final File localPdfFile = File(_compiledPdfUrl!);
      if (await localPdfFile.exists()) {
        try {
          final String userId = authState.user.id;
          final String supabasePath = '$userId/$docId.pdf';
          const String bucketName = 'document-pdfs';

          await Supabase.instance.client.storage
              .from(bucketName)
              .upload(supabasePath, localPdfFile,
                  fileOptions: FileOptions(cacheControl: '3600', upsert: true));

          final String publicUrl = Supabase.instance.client.storage
              .from(bucketName)
              .getPublicUrl(supabasePath);

          finalPdfPath = publicUrl;
          await localPdfFile.delete();
        } catch (e) {
          _showSnackBar('Échec du téléversement PDF: $e', isError: true);
          finalPdfPath = _compiledPdfUrl;
        }
      }
    }

    final doc = DocumentModel(
      id: docId,
      title: _titleCtrl.text.isEmpty ? 'Sans titre' : _titleCtrl.text,
      content: _contentCtrl.text,
      authorId: authState.user.id,
      filiere: authState.profile?.filiere ?? 'general',
      subject: subject,
      isPublic: isPublic,
      isDraft: isDraft,
      createdAt: now,
      updatedAt: now,
      previewHtml: _compiledHtml,
      pdfPath: finalPdfPath,
    );

    context.read<DocumentCubit>().createDocument(doc);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Éditeur LaTeX'),
        backgroundColor: FastHubTheme.surfaceColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Éditeur', icon: Icon(Icons.edit)),
            Tab(text: 'Aperçu', icon: Icon(Icons.visibility)),
            Tab(text: 'PDF', icon: Icon(Icons.picture_as_pdf)),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(FastHubTheme.accentColor),
                  strokeWidth: 2.0,
                ),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _isLoading ? null : _compileLaTeX,
            tooltip: 'Compiler LaTeX',
          ),
          IconButton(
            icon: const Icon(Icons.calculate), // MathJax icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MathJaxDisplayScreen(
                    latexContent: _contentCtrl.text,
                  ),
                ),
              );
            },
            tooltip: 'Prévisualisation MathJax',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : () async {
              final subject = await _showSubjectInputDialog();
              if (subject != null) {
                await _saveDocument(subject: subject, isPublic: false, isDraft: true);
              }
            },
            tooltip: 'Enregistrer le brouillon',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Éditeur Tab - CORRIGÉ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Titre du document',
                    filled: true,
                    fillColor: FastHubTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: FastHubTheme.textSecondary),
                    prefixIcon: Icon(Icons.title, color: FastHubTheme.textColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(
                    color: FastHubTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Info syntaxe
                _buildSyntaxInfo(),
                
                // Barre d'outils
                _buildEditorToolbar(),
                
                // Éditeur LaTeX avec focus
                Expanded(
                  child: _buildLatexEditor(),
                ),
              ],
            ),
          ),
          
          // Preview Tab
          _compiledHtml.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off, 
                          color: FastHubTheme.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      Text('Compilez votre LaTeX pour voir l\'aperçu', 
                          style: TextStyle(color: FastHubTheme.textSecondary)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _compileLaTeX,
                        child: const Text('Compiler maintenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FastHubTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: HtmlWidget(
                    _compiledHtml,
                    textStyle: const TextStyle(color: FastHubTheme.textColor),
                  ),
                ),
          
          // PDF View Tab
          _compiledPdfUrl == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, 
                          color: FastHubTheme.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      Text('Compilez votre LaTeX pour obtenir le PDF', 
                          style: TextStyle(color: FastHubTheme.textSecondary)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _compileLaTeX,
                        child: const Text('Compiler en PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FastHubTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : SfPdfViewer.file(File(_compiledPdfUrl!)),
        ],
      ),
    );
  }
}
