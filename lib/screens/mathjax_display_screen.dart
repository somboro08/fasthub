import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/theme.dart';
import '../services/latex_converter_service.dart';

class MathJaxDisplayScreen extends StatefulWidget {
  final String latexContent;

  const MathJaxDisplayScreen({super.key, required this.latexContent});

  @override
  State<MathJaxDisplayScreen> createState() => _MathJaxDisplayScreenState();
}

class _MathJaxDisplayScreenState extends State<MathJaxDisplayScreen> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(FastHubTheme.backgroundColor)
      ..loadHtmlString(_generateMathJaxHtml(widget.latexContent));
  }

  String _generateMathJaxHtml(String latexContent) {
    return LatexConverterService.generateFullHtml(
      latexContent,
      backgroundColor: FastHubTheme.backgroundColor.toHex(),
      textColor: FastHubTheme.textColor.toHex(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastHubTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Prévisualisation MathJax'),
        backgroundColor: FastHubTheme.surfaceColor,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
