import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class MarkdownEditorScreen extends StatefulWidget {
  final String projectId;
  final String? fileId; // Se nulo, é criação. Se não, é edição.

  const MarkdownEditorScreen({super.key, required this.projectId, this.fileId});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.fileId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appState = Provider.of<AppState>(context, listen: false);
        final project = appState.projects.firstWhere((p) => p.id == widget.projectId);
        final file = project.files.firstWhere((f) => f.id == widget.fileId);
        _titleController.text = file.name.replaceAll('.md', '');
        _contentController.text = file.content;
      });
    }
  }

  void _save() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dê um nome ao arquivo')));
      return;
    }

    if (_isEditing) {
      appState.updateFileContent(widget.projectId, widget.fileId!, _contentController.text);
      // Faltaria atualizar o nome, mas pra simplificar o mock vamos só mudar o conteúdo.
    } else {
      final newFile = ProjectFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${_titleController.text}.md',
        type: 'md',
        createdAt: DateTime.now(),
        content: _contentController.text,
      );
      appState.addFileToProject(widget.projectId, newFile);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo salvo com sucesso!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textSecondary),
        title: const Text('Editor Markdown', style: TextStyle(color: AppTheme.primary, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Salvar'),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Área de Edição
          Expanded(
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    enabled: !_isEditing, // Não deixa mudar nome na edição por agora
                    decoration: const InputDecoration(
                      labelText: 'Nome do Arquivo (sem .md)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Escreva em Markdown aqui...',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Área de Preview
          Expanded(
            child: Container(
              color: AppTheme.background,
              padding: const EdgeInsets.all(24.0),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contentController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) {
                    return const Center(
                      child: Text('Preview do Markdown', style: TextStyle(color: AppTheme.textDisabled)),
                    );
                  }
                  return Markdown(
                    data: value.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: const TextStyle(fontSize: 14),
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
