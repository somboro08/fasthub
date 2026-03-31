import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'fasthub_ai_chat.dart';
import 'pdf_viewer_page.dart';
import '../bloc/ai_chat_cubit.dart';
import '../bloc/auth_cubit.dart';
import '../models/ai_chat_model.dart';
import '../services/ai_service.dart';
import '../theme/theme.dart';

class FastHubAIChat extends StatefulWidget {
  const FastHubAIChat({super.key});

  @override
  State<FastHubAIChat> createState() => _FastHubAIChatState();
}

class _FastHubAIChatState extends State<FastHubAIChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, String> _generatedPdfUrls = {};

  static const Color zinc = Color(0xFFA1A1AA);
  static const String _apiKey = 'AIzaSyDFsaAlQs5ErTSwSGkN4Xt3DzeRqKyOZNY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.read<AIChatCubit>().loadSessions(authState.user.id);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final chatCubit = context.read<AIChatCubit>();
    final chatState = chatCubit.state;

    _controller.clear();

    if (chatState is AIChatSessionsLoaded && chatState.currentSession != null) {
      await chatCubit.sendMessage(text);
    } else {
      await chatCubit.createNewSession(authState.user.id, text);
    }
    _scrollToBottom();
  }

  Future<void> _generatePDF(String msgId, String latexCode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
    );

    try {
      const String latexliteApiKey = 'latexlite-key-f34085582d2803e2';
      final url = Uri.parse('https://latexlite.com/v1/renders-sync');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $latexliteApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'template': latexCode}),
      );

      if (response.statusCode == 200) {
        final authState = context.read<AuthCubit>().state as Authenticated;
        final docId = const Uuid().v4();
        final fileName = 'ai_gen_$docId.pdf';
        final supabasePath = '${authState.user.id}/$fileName';

        await Supabase.instance.client.storage
            .from('document-pdfs')
            .uploadBinary(supabasePath, response.bodyBytes,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

        final publicUrl = Supabase.instance.client.storage
            .from('document-pdfs')
            .getPublicUrl(supabasePath);

        setState(() {
          _generatedPdfUrls[msgId] = publicUrl;
        });

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showSuccessDialog(publicUrl);
        }
      } else {
        throw Exception("Erreur LaTeXLite: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la génération du PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text("PDF Généré", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Votre PDF a été généré et sauvegardé avec succès.", style: TextStyle(color: zinc)),
            const SizedBox(height: 16),
            const Text("Lien du document :", style: TextStyle(color: Colors.white70, fontSize: 12)),
            SelectableText(url, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer", style: TextStyle(color: zinc)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(path: url, title: "Document IA"),
                ),
              );
            },
            child: const Text("Ouvrir le PDF", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF09090B),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        title: const Text("FastHub AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: () {
              // Clear current session to start a new one
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                context.read<AIChatCubit>().loadSessions(authState.user.id);
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<AIChatCubit, AIChatState>(
        listener: (context, state) {
          if (state is AIChatSessionsLoaded && !state.isSending) {
            _scrollToBottom();
          }
          if (state is AIChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AIChatInitial || (state is AIChatLoading && state is! AIChatSessionsLoaded)) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          if (state is AIChatSessionsLoaded) {
            final messages = state.messages;
            final isSending = state.isSending;

            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _buildMessageBubble(msg);
                          },
                        ),
                ),
                if (isSending)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.orangeAccent),
                  ),
                _buildInputZone(isSending),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF09090B),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF18181B)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 40),
                  const SizedBox(height: 10),
                  const Text("Historique AI", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AIChatCubit, AIChatState>(
              builder: (context, state) {
                if (state is AIChatSessionsLoaded) {
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: state.sessions.length,
                    itemBuilder: (context, index) {
                      final session = state.sessions[index];
                      final isSelected = state.currentSession?.id == session.id;
                      return ListTile(
                        leading: Icon(Icons.chat_bubble_outline, color: isSelected ? Colors.orangeAccent : zinc, size: 20),
                        title: Text(
                          session.title,
                          style: TextStyle(color: isSelected ? Colors.white : zinc, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: isSelected,
                        onTap: () {
                          context.read<AIChatCubit>().selectSession(session);
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          onPressed: () => context.read<AIChatCubit>().deleteSession(session.id),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final authState = context.read<AuthCubit>().state;
    String name = "Camarade";
    if (authState is Authenticated) {
      name = authState.profile?.firstName ?? "Camarade";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.orangeAccent.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "Bonjour Camarade $name !",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Comment puis-je t'aider aujourd'hui ?",
            style: TextStyle(color: zinc, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage msg) {
    final isUser = msg.role == 'user';
    final hasLatexBlock = msg.content.contains('\\documentclass');

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? Colors.orangeAccent : const Color(0xFF18181B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                msg.content,
                style: const TextStyle(color: Colors.black, fontSize: 15),
              )
            else ...[
              MarkdownBody(
                data: msg.content,
                selectable: true,
                builders: {
                  'latex': LatexBuilder(),
                },
                extensionSet: md.ExtensionSet(
                  [],
                  [LatexSyntax(), md.EmojiSyntax()],
                ),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white, fontSize: 15),
                  h1: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: Colors.white),
                  code: const TextStyle(
                    backgroundColor: Colors.black54,
                    color: Colors.orangeAccent,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (hasLatexBlock) ...[
                const SizedBox(height: 12),
                if (_generatedPdfUrls.containsKey(msg.id))
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerPage(
                            path: _generatedPdfUrls[msg.id]!,
                            title: "Document IA",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text("Ouvrir le PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      final regex = RegExp(r'\\documentclass[\s\S]*?\\end\{document\}');
                      final match = regex.firstMatch(msg.content);
                      if (match != null) {
                        _generatePDF(msg.id, match.group(0)!);
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text("Générer le PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: zinc, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copié !")));
                    },
                    tooltip: "Copier le message",
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputZone(bool isSending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => isSending ? null : _handleSend(),
                decoration: const InputDecoration(
                  hintText: "Posez votre question...",
                  hintStyle: TextStyle(color: zinc),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isSending ? null : _handleSend,
            child: CircleAvatar(
              backgroundColor: isSending ? Colors.grey : Colors.white,
              child: Icon(
                isSending ? Icons.hourglass_bottom_rounded : Icons.send_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\$\$[\s\S]+\$\$)|(\$[\s\S]+\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    String content = match.group(0)!;
    if (content.startsWith('\$\$')) {
      content = content.substring(2, content.length - 2);
    } else {
      content = content.substring(1, content.length - 1);
    }
    md.Element el = md.Element('latex', [md.Text(content)]);
    parser.addNode(el);
    return true;
  }
}

class LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Math.tex(
        text,
        textStyle: preferredStyle?.copyWith(color: Colors.white, fontSize: 17),
        onErrorFallback: (err) => Text(
          text,
          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
