import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';

/// Sintaxe estilo Obsidian: `[[Título do Documento]]` vira um link clicável
/// que navega para o outro documento do mesmo projeto.
class _WikiLinkSyntax extends md.InlineSyntax {
  _WikiLinkSyntax() : super(r'\[\[([^\]]+)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('wikilink', match[1]!));
    return true;
  }
}

class _WikiLinkBuilder extends MarkdownElementBuilder {
  final void Function(String titulo) onTap;
  _WikiLinkBuilder({required this.onTap});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final titulo = element.textContent;
    return InkWell(
      onTap: () => onTap(titulo),
      child: Text('[[$titulo]]', style: const TextStyle(color: AppTheme.primary, decoration: TextDecoration.underline)),
    );
  }
}

String _tituloDoDocumento(Documento d) {
  final primeiraLinha = d.conteudo.split('\n').first.replaceAll('#', '').trim();
  return primeiraLinha.isEmpty ? 'Documento sem título' : primeiraLinha;
}

class MarkdownEditorScreen extends StatefulWidget {
  final String projectId;
  final String? documentoId; // Se nulo, é criação. Se não, é edição.
  final String? missaoId; // Só usado na criação, vincula o documento a uma missão específica.
  final String? pastaId; // Só usado na criação, vincula o documento a uma pasta específica.

  const MarkdownEditorScreen({super.key, required this.projectId, this.documentoId, this.missaoId, this.pastaId});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  bool _carregando = true;
  bool _salvando = false;
  List<String> _tags = [];
  List<Documento> _outrosDocumentos = [];

  bool get _isEditing => widget.documentoId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<WorkspaceProvider>();
      final documentos = await provider.listarDocumentosDoProjeto(widget.projectId);
      if (_isEditing) {
        final documento = await provider.buscarDocumento(widget.documentoId!);
        if (!mounted) return;
        setState(() {
          _contentController.text = documento.conteudo;
          _tags = List.of(documento.tags);
          _outrosDocumentos = documentos.where((d) => d.id != widget.documentoId).toList();
          _carregando = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _outrosDocumentos = documentos;
          _carregando = false;
        });
      }
    });
  }

  void _aplicarFormatacao(String prefixo, [String sufixo = '']) {
    final selecao = _contentController.selection;
    final texto = _contentController.text;
    if (!selecao.isValid) return;
    final selecionado = selecao.isCollapsed ? '' : selecao.textInside(texto);
    final novoTrecho = '$prefixo$selecionado$sufixo';
    final novoTexto = texto.replaceRange(selecao.start, selecao.end, novoTrecho);
    _contentController.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(offset: selecao.start + prefixo.length + selecionado.length),
    );
  }

  Future<void> _inserirLinkParaDocumento() async {
    final escolhido = await showDialog<Documento>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Vincular a outro documento'),
        content: SizedBox(
          width: 360,
          child: _outrosDocumentos.isEmpty
              ? const Text('Nenhum outro documento neste projeto ainda.', style: TextStyle(color: AppTheme.textSecondary))
              : ListView(
                  shrinkWrap: true,
                  children: _outrosDocumentos.map((d) => ListTile(title: Text(_tituloDoDocumento(d)), onTap: () => Navigator.pop(ctx, d))).toList(),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)))],
      ),
    );
    if (escolhido != null) {
      _aplicarFormatacao('[[${_tituloDoDocumento(escolhido)}]]');
    }
  }

  void _abrirWikiLink(String titulo) {
    final encontrado = _outrosDocumentos.where((d) => _tituloDoDocumento(d).toLowerCase() == titulo.toLowerCase()).toList();
    if (encontrado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nenhum documento encontrado com o título "$titulo".')));
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: widget.projectId, documentoId: encontrado.first.id)));
  }

  void _adicionarTag(String tag) {
    final normalizada = tag.trim();
    if (normalizada.isEmpty || _tags.contains(normalizada)) return;
    setState(() {
      _tags.add(normalizada);
      _tagController.clear();
    });
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escreva algum conteúdo antes de salvar.')));
      return;
    }

    setState(() => _salvando = true);
    final provider = context.read<WorkspaceProvider>();

    if (_isEditing) {
      await provider.atualizarDocumento(widget.documentoId!, _contentController.text, tags: _tags);
    } else {
      await provider.criarDocumento(widget.projectId, _contentController.text, missaoId: widget.missaoId, pastaId: widget.pastaId, tags: _tags);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento salvo com sucesso!')));
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(icon: Icon(icon, size: 18), tooltip: tooltip, onPressed: onPressed, visualDensity: VisualDensity.compact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textSecondary),
        title: const Text('Editor de Documento', style: TextStyle(color: AppTheme.primary, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _salvando ? null : _save,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Salvar'),
            ),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolbarButton(Icons.format_bold, 'Negrito', () => _aplicarFormatacao('**', '**')),
                        _buildToolbarButton(Icons.format_italic, 'Itálico', () => _aplicarFormatacao('_', '_')),
                        _buildToolbarButton(Icons.title, 'Título', () => _aplicarFormatacao('# ')),
                        _buildToolbarButton(Icons.text_fields, 'Subtítulo', () => _aplicarFormatacao('## ')),
                        _buildToolbarButton(Icons.format_list_bulleted, 'Lista', () => _aplicarFormatacao('- ')),
                        _buildToolbarButton(Icons.check_box_outlined, 'Checklist', () => _aplicarFormatacao('- [ ] ')),
                        _buildToolbarButton(Icons.code, 'Bloco de código', () => _aplicarFormatacao('```\n', '\n```')),
                        _buildToolbarButton(Icons.table_chart_outlined, 'Tabela', () => _aplicarFormatacao('\n| Coluna 1 | Coluna 2 |\n| --- | --- |\n| valor | valor |\n')),
                        _buildToolbarButton(Icons.link, 'Vincular a outro documento ([[...]])', _inserirLinkParaDocumento),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.label_outline, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        ..._tags.map((t) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setState(() => _tags.remove(t)),
                                backgroundColor: AppTheme.surfaceRaised,
                                visualDensity: VisualDensity.compact,
                              ),
                            )),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(hintText: 'Nova tag...', border: InputBorder.none, isDense: true),
                            style: const TextStyle(fontSize: 12),
                            onSubmitted: _adicionarTag,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                Expanded(child: _buildEditorEPreview(context)),
              ],
            ),
    );
  }

  Widget _buildEditorEPreview(BuildContext context) {
    final editor = Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: '# Título do documento\n\nEscreva em Markdown aqui... Use [[Título]] para linkar outro documento.',
          border: OutlineInputBorder(),
        ),
        style: AppTheme.monoTextStyle,
      ),
    );

    final preview = Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24.0),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _contentController,
        builder: (context, value, child) {
          if (value.text.isEmpty) {
            return const Center(child: Text('Preview do Markdown', style: TextStyle(color: AppTheme.textDisabled)));
          }
          return Markdown(
            data: value.text,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            inlineSyntaxes: [_WikiLinkSyntax()],
            builders: {'wikilink': _WikiLinkBuilder(onTap: _abrirWikiLink)},
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 14, color: AppTheme.textMain),
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              code: AppTheme.monoTextStyle.copyWith(backgroundColor: AppTheme.surfaceRaised, fontSize: 13),
              tableBorder: TableBorder.all(color: AppTheme.border),
              tableHead: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );

    // Editor e preview lado a lado no desktop; empilhados (editor em cima) no
    // celular, onde não cabem os dois de forma legível na mesma largura.
    if (isMobile(context)) {
      return Column(children: [Expanded(child: editor), const Divider(height: 1, color: AppTheme.border), Expanded(child: preview)]);
    }
    return Row(children: [Expanded(child: editor), Expanded(child: preview)]);
  }
}
