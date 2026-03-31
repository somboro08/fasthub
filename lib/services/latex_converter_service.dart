
import 'dart:convert';

class LatexConverterService {
  // Map des templates pour les environnements simples
  static final Map<String, String> _environmentTemplates = {
    'center': '''
<div class="latex-env env-center" style="text-align: center; margin: 1em 0;">
  {{content}}
</div>
''',
    
    'quote': '''
<div class="latex-env env-quote" 
     style="margin: 1em 40px; padding-left: 15px; 
            border-left: 3px solid #ccc; color: #555;">
  <em>{{content}}</em>
</div>
''',
    
    'quotation': '''
<div class="latex-env env-quotation" 
     style="margin: 1.5em 40px; padding-left: 20px; 
            border-left: 4px solid #7cb342; 
            font-style: italic; text-align: justify;">
  {{content}}
</div>
''',
    
    'abstract': '''
<div class="latex-env env-abstract">
  <div class="env-title" style="font-weight: bold; font-size: 1.1em; 
                                color: #2c3e50; margin-bottom: 0.5em;">
    Résumé
  </div>
  <div class="env-content" style="text-align: justify;">
    {{content}}
  </div>
</div>
''',
    
    'proof': '''
<div class="latex-env env-proof" 
     style="border-left: 3px solid #3498db; padding: 10px 15px; 
            margin: 15px 0; background: #00000079;">
  <div class="env-header" style="font-weight: bold; color: #298009; 
                                 margin-bottom: 0.5em;">
    Preuve
  </div>
  <div class="env-content">
    {{content}}
  </div>
  <div class="env-qed" style="text-align: right; margin-top: 0.5em; 
                              font-size: 1.2em;">
    □
  </div>
</div>
''',
    
    'verbatim': '''
<pre class="latex-env env-verbatim" 
     style="background: #2d3748; color: #e2e8f0; padding: 1em; 
            border-radius: 5px; overflow-x: auto;
            font-family: 'Courier New', monospace; font-size: 0.9em;">
{{content}}
</pre>
''',
    'definition': '''
<div class="latex-env env-definition" 
     style="border: 1px solid #a8dadc; background: #000000; padding: 10px; margin: 15px 0; border-radius: 5px;">
  <div class="env-title" style="font-weight: bold; color: #1d3557; margin-bottom: 5px;">Définition</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'lemma': '''
<div class="latex-env env-lemma" 
     style="border: 1px solid #fca311; background: #000000; padding: 10px; margin: 15px 0; border-radius: 5px;">
  <div class="env-title" style="font-weight: bold; color: #e66c00; margin-bottom: 5px;">Lemme</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'exemple': '''
<div class="latex-env env-exemple" 
     style="border: 1px solid #bdb2ff; background: #ede9ff; padding: 10px; margin: 15px 0; border-radius: 5px;">
  <div class="env-title" style="font-weight: bold; color: #6a0572; margin-bottom: 5px;">Exemple</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'node': '''
<div class="latex-env env-node" 
     style="border: 2px dashed #90a4ae; background: #eceff1; padding: 10px; margin: 15px 0; border-radius: 8px;">
  <div class="env-title" style="font-weight: bold; color: #455a64; margin-bottom: 5px;">Node (Contenu Graphique)</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'draw': '''
<div class="latex-env env-draw" 
     style="border: 2px dashed #f48fb1; background: #ffebee; padding: 10px; margin: 15px 0; border-radius: 8px;">
  <div class="env-title" style="font-weight: bold; color: #c2185b; margin-bottom: 5px;">Draw (Contenu Graphique)</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'theorem': '''
<div class="latex-env env-theorem" 
     style="border: 1px solid #c3e6cb; background: #04040449; padding: 10px; margin: 15px 0; border-left: 5px solid #28a745; border-radius: 5px;">
  <div class="env-title" style="font-weight: bold; color: #218838; margin-bottom: 5px;">Théorème</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'remark': '''
<div class="latex-env env-remark" 
     style="border: 1px solid #ffeeba; background: #2f2f2e; padding: 10px; margin: 15px 0; border-left: 5px solid #ffc107; border-radius: 5px;">
  <div class="env-title" style="font-weight: bold; color: #d39e00; margin-bottom: 5px;">Remarque</div>
  <div class="env-content">{{content}}</div>
</div>
''',
    'tcolorbox': '''
<div class="latex-env env-tcolorbox" 
     style="background-color: #00000068; color: white; padding: 15px; margin: 15px 0; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
  <div class="env-content">{{content}}</div>
</div>
''',
  };

  // Fonction principale de conversion
  static String convertLatexToHtml(String latexContent) {
    String htmlContent = _removePreamble(latexContent);
    htmlContent = _replaceVspaceCommands(htmlContent);
    htmlContent = _replaceSectionCommands(htmlContent);
    htmlContent = _replaceSubsectionCommands(htmlContent);
    htmlContent = _replaceDisplayMath(htmlContent); // Add this line
    
    // Traiter les environnements les uns après les autres
    for (final envName in _environmentTemplates.keys) {
      htmlContent = _replaceEnvironment(envName, htmlContent);
    }
    
    // Gérer les environnements simples sans paramètres
    htmlContent = _handleSimpleEnvironments(htmlContent);
    htmlContent = _replaceInlineMath(htmlContent); // Add this line
    
    // Laisser les formules mathématiques pour MathJax
    htmlContent = _preserveMathContent(htmlContent);
    
    return htmlContent;
  }

  // Remplacer un environnement spécifique
  static String _replaceEnvironment(String envName, String content) {
    final pattern = RegExp(
      r'\\begin\{' + envName + r'\}(.*?)\\end\{' + envName + r'\}',
      dotAll: true,
    );
    
    return content.replaceAllMapped(pattern, (match) {
      final envContent = match.group(1)?.trim() ?? '';
      final template = _environmentTemplates[envName]!;
      return template.replaceAll('{{content}}', envContent);
    });
  }

  // Gérer les environnements simples (itemize, enumerate, etc.)
  static String _handleSimpleEnvironments(String content) {
    String result = content;
    
    // Convertir itemize
    result = result.replaceAllMapped(
      RegExp(r'\\begin\{itemize\}(.*?)\\end\{itemize\}', dotAll: true),
      (match) {
        final items = _extractListItems(match.group(1)!);
        return '''
<ul class="latex-env env-itemize" 
    style="list-style-type: disc; padding-left: 2em; margin: 1em 0;">
  ${items.map((item) => '<li>$item</li>').join('\n')}
</ul>
''';
      },
    );
    
    // Convertir enumerate
    result = result.replaceAllMapped(
      RegExp(r'\\begin\{enumerate\}(.*?)\\end\{enumerate\}', dotAll: true),
      (match) {
        final items = _extractListItems(match.group(1)!);
        return '''
<ol class="latex-env env-enumerate" 
    style="list-style-type: decimal; padding-left: 2em; margin: 1em 0;">
  ${items.map((item) => '<li>$item</li>').join('\n')}
</ol>
''';
      },
    );
    
    return result;
  }

  // Extraire les items d'une liste
  static List<String> _extractListItems(String listContent) {
    final items = <String>[];
    final lines = listContent.split('\n');
    StringBuffer currentItem = StringBuffer();
    
    for (final line in lines) {
      if (line.trim().startsWith(r'\item')) {
        if (currentItem.isNotEmpty) {
          items.add(currentItem.toString());
          currentItem.clear();
        }
        currentItem.write(line.replaceFirst(r'\item', '').trim());
      } else if (currentItem.isNotEmpty) {
        currentItem.write(' $line');
      }
    }
    
    if (currentItem.isNotEmpty) {
      items.add(currentItem.toString());
    }
    
    return items;
  }

  static String _replaceDisplayMath(String content) {
    // Replace $$...$$ with a div containing \[...\] for MathJax
    return content.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true), (match) {
      final mathContent = match.group(1)?.trim() ?? '';
      return '<div class="latex-env env-display-math" style="margin: 1em 0; text-align: center;">\\[$mathContent\\]</div>';
    });
  }

  static String _replaceVspaceCommands(String content) {
    return content.replaceAllMapped(RegExp(r'\\vspace\{([^}]+)\}'), (match) {
      final length = match.group(1)?.trim() ?? '';
      double heightPx = 20.0; // Default height

      // Simple conversion for common LaTeX units to pixels
      if (length.endsWith('cm')) {
        try {
          heightPx = double.parse(length.replaceAll('cm', '')) * 38; // Approx 1cm = 38px
        } catch (_) {}
      } else if (length.endsWith('pt')) {
        try {
          heightPx = double.parse(length.replaceAll('pt', '')) * (16 / 12); // Approx 12pt = 16px
        } catch (_) {}
      } else if (length.endsWith('em')) {
         try {
          heightPx = double.parse(length.replaceAll('em', '')) * 16; // Approx 1em = 16px
        } catch (_) {}
      }
      // Add other units as needed

      return '<div style="height: ${heightPx}px;"></div>';
    });
  }

  static String _replaceSectionCommands(String content) {
    return content.replaceAllMapped(RegExp(r'\\section\{([^}]+)\}'), (match) {
      final title = match.group(1)?.trim() ?? '';
      return '<h2 class="latex-section" style="font-size: 1.8em; margin-top: 1.5em; margin-bottom: 0.8em; color: #3498db;">$title</h2>';
    });
  }

  static String _replaceSubsectionCommands(String content) {
    return content.replaceAllMapped(RegExp(r'\\subsection\{([^}]+)\}'), (match) {
      final title = match.group(1)?.trim() ?? '';
      return '<h3 class="latex-subsection" style="font-size: 1.5em; margin-top: 1.2em; margin-bottom: 0.6em; color: #2ecc71;">$title</h3>';
    });
  }

  static String _replaceInlineMath(String content) {
    // Replace $...$ with a span containing \(...\) for MathJax
    // This regex is tricky: it tries to avoid matching $ when it's not a math delimiter,
    // e.g., in text or as part of a command. It matches $ followed by non-whitespace/non-dollar,
    // then content, then another $ not preceded by non-whitespace/non-dollar.
    // It also tries to avoid escaped dollar signs like \$
    return content.replaceAllMapped(RegExp(r'(?<!\\)\$((?:(?!\$).)*?)(?<!\\)\$', dotAll: true), (match) {
      final mathContent = match.group(1)?.trim() ?? '';
      if (mathContent.isEmpty) return match.group(0)!; // Don't convert empty $ $
      return '<span class="latex-inline-math">\\($mathContent\\)</span>';
    });
  }

  // Préserver le contenu mathématique pour MathJax
  static String _preserveMathContent(String content) {
    // Laisser les délimiteurs mathématiques intacts
    // \(...\) et \[...\] seront traités par MathJax
    return content;
  }

  // Générer le HTML complet avec MathJax
  static String generateFullHtml(String latexContent, {String? backgroundColor, String? textColor}) {
    final convertedContent = convertLatexToHtml(latexContent);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Prévisualisation LaTeX</title>
    <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <style>
        body {
            background-color: ${backgroundColor ?? '#1a1a2e'};
            color: ${textColor ?? '#e6e6e6'};
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            font-size: 16px;
            overflow-y: auto; /* Added for vertical scrolling */
        }
        
        .latex-env {
            margin: 1em 0;
            transition: all 0.3s ease;
        }
        
        .env-quote:hover, .env-quotation:hover {
            border-left-color: #3498db;
            background-color: rgba(52, 152, 219, 0.05);
        }
        
        .env-verbatim {
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        
        .env-proof:hover {
            background-color: rgba(52, 152, 219, 0.1);
        }
        
        /* Styles pour MathJax */
        .MathJax {
            font-size: 1.1em !important;
        }
        
        mjx-container {
            overflow-x: auto;
            overflow-y: hidden;
        }
    </style>
    <script>
        MathJax = {
            tex: {
                inlineMath: [['\$', '\$'], ['\\(', '\\)']],
                displayMath: [['\$\$', '\$\$'], ['\\[', '\\]']],
                processEnvironments: false, // Important: ne pas traiter les environnements LaTeX
                processRefs: false
            },
            options: {
                skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre'],
                ignoreHtmlClass: 'latex-env' // Ignorer nos environnements convertis
            },
            svg: {
                fontCache: 'global'
            },
            startup: {
                ready: () => {
                    MathJax.startup.defaultReady();
                    // Removed: MathJax.startup.promise.then(() => {
                    // Removed:     window.frameElement.height = document.body.scrollHeight + 50;
                    // Removed: });
                }
            }
        };
    </script>
</head>
<body>
    $convertedContent
</body>
</html>
''';
  }

  static List<String> extractUsedPackages(String latexContent) {
    final packages = <String>[];
    final docClassMatch = RegExp(r'\\documentclass\{[^}]*\}').firstMatch(latexContent);
    if (docClassMatch == null) {
      return packages; // No document class, likely not a full document
    }

    final preambleEndIndex = latexContent.indexOf(r'\begin{document}');
    if (preambleEndIndex == -1) {
      return packages; // No \begin{document}, entire content is preamble or incomplete
    }

    final preamble = latexContent.substring(0, preambleEndIndex);

    final usepackagePattern = RegExp(r'\\usepackage(\[[^\]]*\])?\{([^}]+)\}');
    for (final match in usepackagePattern.allMatches(preamble)) {
      final packageNamesString = match.group(2); // e.g., "amsmath,amsfonts"
      if (packageNamesString != null) {
        packages.addAll(packageNamesString.split(',').map((p) => p.trim()));
      }
    }
    return packages;
  }

  static String _removePreamble(String latexContent) {
    final beginDocumentMatch = RegExp(r'\\begin\{document\}').firstMatch(latexContent);
    if (beginDocumentMatch == null) {
      return latexContent; // No \begin{document}, return original content
    }
    // Return content after \begin{document}
    final contentAfterBeginDocument = latexContent.substring(beginDocumentMatch.end);

    // Also remove everything after \end{document} if it exists
    final endDocumentMatch = RegExp(r'\\end\{document\}').firstMatch(contentAfterBeginDocument);
    if (endDocumentMatch != null) {
      return contentAfterBeginDocument.substring(0, endDocumentMatch.start);
    }

    return contentAfterBeginDocument;
  }
}
