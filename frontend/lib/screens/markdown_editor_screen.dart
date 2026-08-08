import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/providers/auth_provider.dart';

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
      child: Text(
        '[[$titulo]]',
        style: const TextStyle(
          color: AppTheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

/// Se o conteúdo começa com front-matter YAML (`---` como primeiríssima
/// linha, caso do Laudo — ver [MarkdownEditorScreen]), devolve o índice do
/// `---` de fechamento. Senão, `null`.
int? _indiceFechamentoFrontMatter(String conteudo) {
  final linhas = conteudo.split('\n');
  if (linhas.isEmpty || linhas.first.trim() != '---') return null;
  for (var i = 1; i < linhas.length; i++) {
    if (linhas[i].trim() == '---') return i;
  }
  return null;
}

/// Título de um Documento para exibição/wikilink: o valor de `title:` quando
/// o conteúdo começa com front-matter YAML, senão a primeira linha do
/// markdown (comportamento antigo).
String _tituloDoDocumento(Documento d) {
  final indiceFechamento = _indiceFechamentoFrontMatter(d.conteudo);
  if (indiceFechamento != null) {
    final linhas = d.conteudo.split('\n');
    for (var i = 1; i < indiceFechamento; i++) {
      final match = RegExp(
        r'^title\s*:\s*(.+)$',
      ).firstMatch(linhas[i].trimLeft());
      if (match != null) {
        var valor = match.group(1)!.trim();
        if (valor.length >= 2 && valor.startsWith('"') && valor.endsWith('"')) {
          valor = valor.substring(1, valor.length - 1).replaceAll('\\"', '"');
        }
        return valor.isEmpty ? 'Laudo sem título' : valor;
      }
    }
    return 'Laudo sem título';
  }
  final primeiraLinha = d.conteudo.split('\n').first.replaceAll('#', '').trim();
  return primeiraLinha.isEmpty ? 'Documento sem título' : primeiraLinha;
}

enum _PainelDireito { preview, pdf }

class MarkdownEditorScreen extends StatefulWidget {
  final String projectId;
  final String? documentoId; // Se nulo, é criação. Se não, é edição.
  final String?
  missaoId; // Só usado na criação, vincula o documento a uma missão específica.
  final String?
  pastaId; // Só usado na criação, vincula o documento a uma pasta específica.

  const MarkdownEditorScreen({
    super.key,
    required this.projectId,
    this.documentoId,
    this.missaoId,
    this.pastaId,
  });

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

  // Id do documento salvo — nulo até a primeira gravação, quando a tela foi
  // aberta em modo de criação. Compilar o laudo exige um documento salvo (o
  // backend compila o `conteudo` já persistido, não o texto ainda não salvo
  // no editor — o PDF gerado tem que corresponder a uma versão auditada).
  String? _documentoId;
  bool get _isEditing => _documentoId != null;

  _PainelDireito _painelDireito = _PainelDireito.preview;
  bool _compilando = false;
  bool _baixandoPdf = false;
  String? _logCompilacaoComErro;

  final String _pdfViewType = 'laudo-pdf-view-${UniqueKey()}';
  late final html.IFrameElement _pdfIframe;
  String? _pdfBlobUrlAtual;

  @override
  void initState() {
    super.initState();
    _documentoId = widget.documentoId;

    _pdfIframe = html.IFrameElement()..style.border = 'none';
    ui_web.platformViewRegistry.registerViewFactory(
      _pdfViewType,
      (int viewId) => _pdfIframe,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<WorkspaceProvider>();
      final documentos = await provider.listarDocumentosDoProjeto(
        widget.projectId,
      );
      if (_isEditing) {
        final documento = await provider.buscarDocumento(_documentoId!);
        if (!mounted) return;
        setState(() {
          _contentController.text = documento.conteudo;
          _tags = List.of(documento.tags);
          _outrosDocumentos = documentos
              .where((d) => d.id != _documentoId)
              .toList();
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

  @override
  void dispose() {
    if (_pdfBlobUrlAtual != null) html.Url.revokeObjectUrl(_pdfBlobUrlAtual!);
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _aplicarFormatacao(String prefixo, [String sufixo = '']) {
    final selecao = _contentController.selection;
    final texto = _contentController.text;
    if (!selecao.isValid) return;
    final selecionado = selecao.isCollapsed ? '' : selecao.textInside(texto);
    final novoTrecho = '$prefixo$selecionado$sufixo';
    final novoTexto = texto.replaceRange(
      selecao.start,
      selecao.end,
      novoTrecho,
    );
    _contentController.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(
        offset: selecao.start + prefixo.length + selecionado.length,
      ),
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
              ? const Text(
                  'Nenhum outro documento neste projeto ainda.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              : ListView(
                  shrinkWrap: true,
                  children: _outrosDocumentos
                      .map(
                        (d) => ListTile(
                          title: Text(_tituloDoDocumento(d)),
                          onTap: () => Navigator.pop(ctx, d),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
    if (escolhido != null) {
      _aplicarFormatacao('[[${_tituloDoDocumento(escolhido)}]]');
    }
  }

  void _abrirWikiLink(String titulo) {
    final encontrado = _outrosDocumentos
        .where(
          (d) => _tituloDoDocumento(d).toLowerCase() == titulo.toLowerCase(),
        )
        .toList();
    if (encontrado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum documento encontrado com o título "$titulo".'),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MarkdownEditorScreen(
          projectId: widget.projectId,
          documentoId: encontrado.first.id,
        ),
      ),
    );
  }

  void _adicionarTag(String tag) {
    final normalizada = tag.trim();
    if (normalizada.isEmpty || _tags.contains(normalizada)) return;
    setState(() {
      _tags.add(normalizada);
      _tagController.clear();
    });
  }

  /// Persiste o conteúdo atual (criando o documento se ainda não existir) e
  /// devolve o id salvo — usado tanto pelo botão "Salvar" quanto, antes de
  /// cada compilação, para garantir que o PDF sempre corresponda a uma
  /// versão que já passou pela auditoria (nunca a texto ainda não salvo).
  Future<String> _garantirSalvo() async {
    final provider = context.read<WorkspaceProvider>();
    if (_documentoId == null) {
      final documento = await provider.criarDocumento(
        widget.projectId,
        _contentController.text,
        missaoId: widget.missaoId,
        pastaId: widget.pastaId,
        tags: _tags,
      );
      _documentoId = documento.id;
    } else {
      await provider.atualizarDocumento(
        _documentoId!,
        _contentController.text,
        tags: _tags,
      );
    }
    return _documentoId!;
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva algum conteúdo antes de salvar.'),
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    await _garantirSalvo();

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documento salvo com sucesso!')),
    );
  }

  void _mostrarLogCompilacao(String log) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Erro ao compilar o laudo'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Text(
              log,
              style: AppTheme.monoTextStyle.copyWith(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarEBaixarPdf() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva algum conteúdo antes de gerar o PDF.'),
        ),
      );
      return;
    }

    setState(() => _baixandoPdf = true);
    final provider = context.read<WorkspaceProvider>();
    try {
      final id = await _garantirSalvo();
      final resultado = await provider.compilarLaudo(id);
      if (!resultado.sucesso) {
        if (mounted) _mostrarLogCompilacao(resultado.log);
        return;
      }

      final bytes = await provider.baixarPdfLaudo(id);
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'laudo-$id.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _baixandoPdf = false);
    }
  }

  Future<void> _compilarEVisualizar() async {
    setState(() {
      _compilando = true;
      _logCompilacaoComErro = null;
    });
    final provider = context.read<WorkspaceProvider>();
    try {
      final id = await _garantirSalvo();
      final resultado = await provider.compilarLaudo(id);
      if (!resultado.sucesso) {
        setState(() => _logCompilacaoComErro = resultado.log);
        return;
      }

      final bytes = await provider.baixarPdfLaudo(id);
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final novaUrl = html.Url.createObjectUrlFromBlob(blob);
      final urlAntiga = _pdfBlobUrlAtual;
      _pdfIframe.src = novaUrl;
      _pdfBlobUrlAtual = novaUrl;
      if (urlAntiga != null) html.Url.revokeObjectUrl(urlAntiga);
    } catch (e) {
      setState(() => _logCompilacaoComErro = 'Erro ao compilar: $e');
    } finally {
      if (mounted) setState(() => _compilando = false);
    }
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modoDemo = context.watch<AuthProvider>().modoDemo;

    final mobile = isMobile(context);
    final tooltipGerarPdf = modoDemo
        ? 'Geração de PDF real exige a plataforma rodando de verdade — indisponível no modo demonstração.'
        : 'Compila o Markdown (com front-matter Eisvogel) em PDF e baixa o arquivo';
    final iconeGerarPdf = _baixandoPdf
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.textSecondary,
            ),
          )
        : const Icon(Icons.picture_as_pdf_outlined, size: 18);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textSecondary),
        // No celular a tela é estreita demais pros dois botões com rótulo +
        // título caberem numa linha só — vira ícone com tooltip.
        title: Text(
          mobile ? 'Editor' : 'Editor de Documento',
          style: const TextStyle(color: AppTheme.primary, fontSize: 16),
        ),
        actions: mobile
            ? [
                Tooltip(
                  message: tooltipGerarPdf,
                  child: IconButton(
                    onPressed: (modoDemo || _baixandoPdf)
                        ? null
                        : _gerarEBaixarPdf,
                    icon: iconeGerarPdf,
                  ),
                ),
                IconButton(
                  onPressed: _salvando ? null : _save,
                  icon: const Icon(Icons.save),
                  tooltip: 'Salvar',
                ),
                const SizedBox(width: 8),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Tooltip(
                    message: tooltipGerarPdf,
                    child: OutlinedButton.icon(
                      onPressed: (modoDemo || _baixandoPdf)
                          ? null
                          : _gerarEBaixarPdf,
                      icon: iconeGerarPdf,
                      label: const Text('Gerar PDF'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Salvar'),
                  ),
                ),
              ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _buildToolbarButton(
                            Icons.format_bold,
                            'Negrito',
                            () => _aplicarFormatacao('**', '**'),
                          ),
                          _buildToolbarButton(
                            Icons.format_italic,
                            'Itálico',
                            () => _aplicarFormatacao('_', '_'),
                          ),
                          _buildToolbarButton(
                            Icons.title,
                            'Título',
                            () => _aplicarFormatacao('# '),
                          ),
                          _buildToolbarButton(
                            Icons.text_fields,
                            'Subtítulo',
                            () => _aplicarFormatacao('## '),
                          ),
                          _buildToolbarButton(
                            Icons.format_list_bulleted,
                            'Lista',
                            () => _aplicarFormatacao('- '),
                          ),
                          _buildToolbarButton(
                            Icons.check_box_outlined,
                            'Checklist',
                            () => _aplicarFormatacao('- [ ] '),
                          ),
                          _buildToolbarButton(
                            Icons.code,
                            'Bloco de código',
                            () => _aplicarFormatacao('```\n', '\n```'),
                          ),
                          _buildToolbarButton(
                            Icons.table_chart_outlined,
                            'Tabela',
                            () => _aplicarFormatacao(
                              '\n| Coluna 1 | Coluna 2 |\n| --- | --- |\n| valor | valor |\n',
                            ),
                          ),
                          _buildToolbarButton(
                            Icons.link,
                            'Vincular a outro documento ([[...]])',
                            _inserirLinkParaDocumento,
                          ),
                          const SizedBox(width: 12),
                          const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: AppTheme.border,
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.label_outline,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          ..._tags.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onDeleted: () =>
                                    setState(() => _tags.remove(t)),
                                backgroundColor: AppTheme.surfaceRaised,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: 'Nova tag...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 12),
                              onSubmitted: _adicionarTag,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),
                Expanded(child: _buildEditorEPreview(context, modoDemo)),
              ],
            ),
    );
  }

  Widget _buildSeletorPainel(bool modoDemo) {
    Widget botao(
      _PainelDireito valor,
      IconData icon,
      String rotulo, {
      String? tooltipDesabilitado,
    }) {
      final selecionado = _painelDireito == valor;
      final desabilitado = valor == _PainelDireito.pdf && modoDemo;
      final botaoWidget = TextButton.icon(
        onPressed: desabilitado
            ? null
            : () {
                setState(() => _painelDireito = valor);
                if (valor == _PainelDireito.pdf) _compilarEVisualizar();
              },
        icon: Icon(
          icon,
          size: 16,
          color: desabilitado
              ? AppTheme.textDisabled
              : (selecionado ? AppTheme.primary : AppTheme.textSecondary),
        ),
        label: Text(
          rotulo,
          style: TextStyle(
            fontSize: 12,
            color: desabilitado
                ? AppTheme.textDisabled
                : (selecionado ? AppTheme.primary : AppTheme.textSecondary),
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: selecionado && !desabilitado
              ? AppTheme.surfaceRaised
              : null,
          visualDensity: VisualDensity.compact,
        ),
      );
      if (desabilitado && tooltipDesabilitado != null) {
        return Tooltip(message: tooltipDesabilitado, child: botaoWidget);
      }
      return botaoWidget;
    }

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          botao(
            _PainelDireito.preview,
            Icons.remove_red_eye_outlined,
            'Preview',
          ),
          const SizedBox(width: 4),
          botao(
            _PainelDireito.pdf,
            Icons.picture_as_pdf_outlined,
            'Visualizar PDF',
            tooltipDesabilitado:
                'Geração de PDF real exige a plataforma rodando de verdade — indisponível no modo demonstração.',
          ),
          if (_painelDireito == _PainelDireito.pdf && !modoDemo) ...[
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              tooltip: 'Recompilar com o conteúdo atual',
              onPressed: _compilando ? null : _compilarEVisualizar,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConteudoPainelDireito(BuildContext context) {
    if (_painelDireito == _PainelDireito.preview) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: _contentController,
        builder: (context, value, child) {
          if (value.text.isEmpty) {
            return const Center(
              child: Text(
                'Preview do Markdown',
                style: TextStyle(color: AppTheme.textDisabled),
              ),
            );
          }
          return Markdown(
            data: value.text,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            inlineSyntaxes: [_WikiLinkSyntax()],
            builders: {'wikilink': _WikiLinkBuilder(onTap: _abrirWikiLink)},
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: const TextStyle(fontSize: 14, color: AppTheme.textMain),
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                  h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                  code: AppTheme.monoTextStyle.copyWith(
                    backgroundColor: AppTheme.surfaceRaised,
                    fontSize: 13,
                  ),
                  tableBorder: TableBorder.all(color: AppTheme.border),
                  tableHead: const TextStyle(fontWeight: FontWeight.bold),
                ),
          );
        },
      );
    }

    // Painel "Visualizar PDF"
    if (_compilando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 12),
            Text(
              'Compilando laudo (Pandoc + Eisvogel)...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (_logCompilacaoComErro != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.statusRejected,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Falha ao compilar o laudo',
                  style: TextStyle(
                    color: AppTheme.statusRejected,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _logCompilacaoComErro!,
                  style: AppTheme.monoTextStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_pdfBlobUrlAtual == null) {
      return const Center(
        child: Text(
          'Clique em "Visualizar PDF" para compilar',
          style: TextStyle(color: AppTheme.textDisabled),
        ),
      );
    }
    return HtmlElementView(viewType: _pdfViewType);
  }

  Widget _buildEditorEPreview(BuildContext context, bool modoDemo) {
    final editor = Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText:
              '# Título do documento\n\nEscreva em Markdown aqui... Use [[Título]] para linkar outro documento.',
          border: OutlineInputBorder(),
        ),
        style: AppTheme.monoTextStyle,
      ),
    );

    final painelDireito = Column(
      children: [
        _buildSeletorPainel(modoDemo),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: Container(
            color: AppTheme.background,
            padding: _painelDireito == _PainelDireito.preview
                ? const EdgeInsets.all(24.0)
                : EdgeInsets.zero,
            child: _buildConteudoPainelDireito(context),
          ),
        ),
      ],
    );

    // Editor e preview lado a lado no desktop; empilhados (editor em cima) no
    // celular, onde não cabem os dois de forma legível na mesma largura.
    if (isMobile(context)) {
      return Column(
        children: [
          Expanded(child: editor),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: painelDireito),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: editor),
        Expanded(child: painelDireito),
      ],
    );
  }
}
