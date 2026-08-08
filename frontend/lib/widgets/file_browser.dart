import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/screens/markdown_editor_screen.dart';

enum _TipoItem { pasta, arquivo, documento }

/// Navegador de pastas estilo Drive para os arquivos e documentos de um
/// projeto: breadcrumb, subpastas, upload e criação de documento sempre
/// dentro da pasta atual. Renomear segue o padrão do Windows/Drive: clique
/// direito (ou o menu "⋮", ou toque longo no celular) → "Renomear" → o nome
/// vira editável ali mesmo no card, sem diálogo.
class FileBrowser extends StatefulWidget {
  final String projetoId;

  const FileBrowser({super.key, required this.projetoId});

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final List<Pasta> _pilha = []; // breadcrumb — vazio = raiz
  bool _carregando = true;
  List<Pasta> _pastas = [];
  List<Arquivo> _arquivos = [];
  List<Documento> _documentos = [];

  String? _renomeandoId;
  TextEditingController? _renomeController;
  FocusNode? _renomeFocusNode;

  String? get _pastaAtualId => _pilha.isEmpty ? null : _pilha.last.id;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _renomeController?.dispose();
    _renomeFocusNode?.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    final pastas = await provider.listarPastas(
      widget.projetoId,
      pastaPaiId: _pastaAtualId,
    );
    final arquivos = await provider.listarArquivosDoProjeto(
      widget.projetoId,
      pastaId: _pastaAtualId ?? 'raiz',
    );
    final documentos = await provider.listarDocumentosDoProjeto(
      widget.projetoId,
      pastaId: _pastaAtualId ?? 'raiz',
    );
    if (!mounted) return;
    setState(() {
      _pastas = pastas;
      _arquivos = arquivos;
      _documentos = documentos;
      _carregando = false;
    });
  }

  void _entrarNaPasta(Pasta pasta) {
    setState(() => _pilha.add(pasta));
    _carregar();
  }

  void _voltarPara(int index) {
    setState(() {
      if (index < 0) {
        _pilha.clear();
      } else {
        _pilha.removeRange(index + 1, _pilha.length);
      }
    });
    _carregar();
  }

  Future<void> _novaPasta() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nova Pasta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome da pasta'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final provider = context.read<WorkspaceProvider>();
              await provider.criarPasta(
                widget.projetoId,
                controller.text.trim(),
                pastaPaiId: _pastaAtualId,
              );
              if (context.mounted) Navigator.pop(ctx);
              await _carregar();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // --- Renomear (clique direito / menu "⋮" / toque longo → edição inline) ---

  void _iniciarRenomeacao(String id, String nomeAtual) {
    _renomeFocusNode?.dispose();
    final controller = TextEditingController(text: nomeAtual);
    final focusNode = FocusNode();
    // Salva ao perder o foco (clicar fora) — mesmo comportamento do Explorer/Drive.
    focusNode.addListener(() {
      if (!focusNode.hasFocus && _renomeandoId == id) {
        _confirmarRenomeacao(id: id, nomeAtual: nomeAtual);
      }
    });
    setState(() {
      _renomeandoId = id;
      _renomeController = controller;
      _renomeFocusNode = focusNode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
      // Pré-seleciona só o nome-base (sem extensão) em arquivos, igual o
      // Explorer faz — evita que digitar por cima apague a extensão à toa.
      final pontoExtensao =
          nomeAtual.contains('.') && !nomeAtual.startsWith('.')
          ? nomeAtual.lastIndexOf('.')
          : nomeAtual.length;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: pontoExtensao,
      );
    });
  }

  void _cancelarRenomeacao() {
    if (_renomeandoId == null) return;
    setState(() => _renomeandoId = null);
  }

  Future<void> _confirmarRenomeacao({
    required String id,
    required String nomeAtual,
  }) async {
    final novoNome = _renomeController?.text.trim() ?? '';
    if (!mounted) return;
    setState(() => _renomeandoId = null);
    if (novoNome.isEmpty || novoNome == nomeAtual) return;

    final provider = context.read<WorkspaceProvider>();
    if (_pastas.any((p) => p.id == id)) {
      await provider.renomearPasta(id, novoNome);
    } else if (_arquivos.any((a) => a.id == id)) {
      await provider.renomearArquivo(id, novoNome);
    } else {
      final documento = _documentos.firstWhere((d) => d.id == id);
      await provider.atualizarDocumento(
        id,
        _substituirTitulo(documento.conteudo, novoNome),
        tags: documento.tags,
      );
    }
    if (mounted) await _carregar();
  }

  /// Documento não tem campo de nome próprio — o "título" mostrado normalmente
  /// é a primeira linha do markdown. Exceção: um Laudo começa com front-matter
  /// YAML (`---\ntitle: ...\n---`), que só é reconhecido pelo Pandoc quando o
  /// `---` é literalmente a primeira linha do arquivo — por isso, nesse caso,
  /// renomear tem que editar o campo `title:` *dentro* do bloco, nunca inserir
  /// uma linha `# ...` acima dele (isso quebraria o front-matter inteiro e a
  /// compilação do laudo).
  String _substituirTitulo(String conteudo, String novoTitulo) {
    final indiceFechamento = _indiceFechamentoFrontMatter(conteudo);
    if (indiceFechamento != null) {
      final linhas = conteudo.split('\n');
      final tituloEscapado = novoTitulo.replaceAll('"', '\\"');
      final novaLinha = 'title: "$tituloEscapado"';
      var indiceTitle = -1;
      for (var i = 1; i < indiceFechamento; i++) {
        if (RegExp(r'^title\s*:').hasMatch(linhas[i].trimLeft())) {
          indiceTitle = i;
          break;
        }
      }
      if (indiceTitle != -1) {
        linhas[indiceTitle] = novaLinha;
      } else {
        linhas.insert(indiceFechamento, novaLinha);
      }
      return linhas.join('\n');
    }

    final linhas = conteudo.split('\n');
    if (linhas.isNotEmpty && linhas.first.trimLeft().startsWith('#')) {
      final prefixo =
          RegExp(r'^(#+)').firstMatch(linhas.first.trimLeft())?.group(1) ?? '#';
      linhas[0] = '$prefixo $novoTitulo';
    } else {
      linhas.insert(0, '# $novoTitulo');
    }
    return linhas.join('\n');
  }

  /// Se o conteúdo começa com front-matter YAML (`---` como primeiríssima
  /// linha), devolve o índice do `---` de fechamento. Senão, `null`.
  int? _indiceFechamentoFrontMatter(String conteudo) {
    final linhas = conteudo.split('\n');
    if (linhas.isEmpty || linhas.first.trim() != '---') return null;
    for (var i = 1; i < linhas.length; i++) {
      if (linhas[i].trim() == '---') return i;
    }
    return null;
  }

  /// Título de exibição de um Documento: o valor de `title:` quando o
  /// conteúdo começa com front-matter YAML (caso do Laudo), senão a primeira
  /// linha do markdown — mesma regra usada em [MarkdownEditorScreen].
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
          if (valor.length >= 2 &&
              valor.startsWith('"') &&
              valor.endsWith('"')) {
            valor = valor.substring(1, valor.length - 1).replaceAll('\\"', '"');
          }
          return valor.isEmpty ? 'Laudo sem título' : valor;
        }
      }
      return 'Laudo sem título';
    }
    final primeiraLinha = d.conteudo
        .split('\n')
        .first
        .replaceAll('#', '')
        .trim();
    return primeiraLinha.isEmpty ? 'Documento sem título' : primeiraLinha;
  }

  Future<void> _removerPasta(Pasta pasta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Remover "${pasta.nome}"?'),
        content: const Text(
          'Os arquivos e documentos dentro dela voltam para a pasta anterior (não são apagados).',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRejected,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<WorkspaceProvider>().removerPasta(pasta.id);
      await _carregar();
    }
  }

  Future<void> _fazerUpload() async {
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    if (resultado == null ||
        resultado.files.isEmpty ||
        resultado.files.single.bytes == null)
      return;
    if (!mounted) return;
    final provider = context.read<WorkspaceProvider>();
    await provider.uploadArquivo(
      widget.projetoId,
      bytes: resultado.files.single.bytes!,
      nomeArquivo: resultado.files.single.name,
      pastaId: _pastaAtualId ?? 'raiz',
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo enviado — hash SHA-256 calculado.'),
        ),
      );
    await _carregar();
  }

  Future<void> _verVerificacao(Arquivo arquivo) async {
    final provider = context.read<WorkspaceProvider>();
    final resultado = await provider.verificarIntegridade(arquivo.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(arquivo.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hash SHA-256:', style: Theme.of(context).textTheme.bodySmall),
            SelectableText(
              arquivo.hashSha256,
              style: AppTheme.monoTextStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  resultado['integro'] == true ? Icons.verified : Icons.error,
                  color: resultado['integro'] == true
                      ? AppTheme.statusApproved
                      : AppTheme.statusRejected,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  resultado['integro'] == true
                      ? 'Integridade verificada'
                      : 'Hash não confere!',
                  style: TextStyle(
                    color: resultado['integro'] == true
                        ? AppTheme.statusApproved
                        : AppTheme.statusRejected,
                  ),
                ),
              ],
            ),
          ],
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

  // --- Menu de contexto (clique direito, "⋮", toque longo) ---

  List<PopupMenuEntry<String>> _itensMenu(_TipoItem tipo) => [
    PopupMenuItem(
      value: 'renomear',
      height: 36,
      child: Row(
        children: const [
          Icon(
            Icons.drive_file_rename_outline,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          SizedBox(width: 10),
          Text('Renomear', style: TextStyle(fontSize: 13)),
        ],
      ),
    ),
    if (tipo == _TipoItem.arquivo)
      PopupMenuItem(
        value: 'verificar',
        height: 36,
        child: Row(
          children: const [
            Icon(
              Icons.verified_outlined,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            SizedBox(width: 10),
            Text('Verificar integridade', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    if (tipo == _TipoItem.pasta) ...[
      const PopupMenuDivider(height: 8),
      PopupMenuItem(
        value: 'remover',
        height: 36,
        child: Row(
          children: const [
            Icon(
              Icons.delete_outline,
              size: 16,
              color: AppTheme.statusRejected,
            ),
            SizedBox(width: 10),
            Text(
              'Remover',
              style: TextStyle(fontSize: 13, color: AppTheme.statusRejected),
            ),
          ],
        ),
      ),
    ],
  ];

  void _executarAcaoMenu(
    String acao, {
    required _TipoItem tipo,
    required String id,
    required String nomeAtual,
  }) {
    switch (acao) {
      case 'renomear':
        _iniciarRenomeacao(id, nomeAtual);
        break;
      case 'verificar':
        _verVerificacao(_arquivos.firstWhere((a) => a.id == id));
        break;
      case 'remover':
        _removerPasta(_pastas.firstWhere((p) => p.id == id));
        break;
    }
  }

  Future<void> _abrirMenuContexto(
    Offset posicaoGlobal, {
    required _TipoItem tipo,
    required String id,
    required String nomeAtual,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selecionado = await showMenu<String>(
      context: context,
      color: AppTheme.surfaceRaised,
      position: RelativeRect.fromRect(
        posicaoGlobal & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: _itensMenu(tipo),
    );
    if (selecionado != null && mounted)
      _executarAcaoMenu(selecionado, tipo: tipo, id: id, nomeAtual: nomeAtual);
  }

  Widget _botaoMenu({
    required _TipoItem tipo,
    required String id,
    required String nomeAtual,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppTheme.textSecondary,
      ),
      padding: EdgeInsets.zero,
      color: AppTheme.surfaceRaised,
      tooltip: 'Mais opções',
      onSelected: (acao) =>
          _executarAcaoMenu(acao, tipo: tipo, id: id, nomeAtual: nomeAtual),
      itemBuilder: (ctx) => _itensMenu(tipo),
    );
  }

  /// Campo de texto que substitui o rótulo do card enquanto está renomeando
  /// — Enter confirma, Esc cancela, clicar fora confirma (via listener do
  /// FocusNode em [_iniciarRenomeacao]).
  Widget _campoRenomeacao(String id, String nomeAtual) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelarRenomeacao();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _renomeController,
        focusNode: _renomeFocusNode,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _confirmarRenomeacao(id: id, nomeAtual: nomeAtual),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botoes = [
      OutlinedButton.icon(
        onPressed: _novaPasta,
        icon: const Icon(Icons.create_new_folder_outlined, size: 16),
        label: const Text('Nova Pasta'),
      ),
      OutlinedButton.icon(
        onPressed: _fazerUpload,
        icon: const Icon(Icons.upload_file, size: 16),
        label: const Text('Upload'),
      ),
      ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkdownEditorScreen(
                projectId: widget.projetoId,
                pastaId: _pastaAtualId ?? 'raiz',
              ),
            ),
          );
          await _carregar();
        },
        icon: const Icon(Icons.note_add, size: 16),
        label: const Text('Novo Documento'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile(context))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: botoes),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildBreadcrumb()),
              Wrap(spacing: 8, children: botoes),
            ],
          ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : (_pastas.isEmpty && _arquivos.isEmpty && _documentos.isEmpty)
                ? const Center(
                    child: Text(
                      'Pasta vazia. Crie uma subpasta, faça upload ou adicione um documento.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    // Extensão máxima em vez de contagem fixa de colunas: reflui
                    // sozinho pro número de colunas certo em qualquer largura
                    // (considera o espaço real do grid, não a tela inteira).
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                    itemCount:
                        _pastas.length + _arquivos.length + _documentos.length,
                    itemBuilder: (context, index) {
                      if (index < _pastas.length)
                        return _buildPastaItem(context, _pastas[index]);
                      final indexArquivo = index - _pastas.length;
                      if (indexArquivo < _arquivos.length)
                        return _buildArquivoItem(
                          context,
                          _arquivos[indexArquivo],
                        );
                      return _buildDocumentoItem(
                        context,
                        _documentos[indexArquivo - _arquivos.length],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          onTap: () => _voltarPara(-1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.home_outlined, size: 16, color: AppTheme.primary),
              SizedBox(width: 4),
              Text(
                'Raiz',
                style: TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
            ],
          ),
        ),
        for (var i = 0; i < _pilha.length; i++) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textDisabled,
            ),
          ),
          InkWell(
            onTap: () => _voltarPara(i),
            child: Text(
              _pilha[i].nome,
              style: TextStyle(
                color: i == _pilha.length - 1
                    ? AppTheme.textMain
                    : AppTheme.primary,
                fontSize: 13,
                fontWeight: i == _pilha.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Offset _centroDoItem(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Widget _buildPastaItem(BuildContext gridContext, Pasta pasta) {
    final renomeando = _renomeandoId == pasta.id;
    return Stack(
      children: [
        InkWell(
          onTap: renomeando ? null : () => _entrarNaPasta(pasta),
          onSecondaryTapDown: renomeando
              ? null
              : (d) => _abrirMenuContexto(
                  d.globalPosition,
                  tipo: _TipoItem.pasta,
                  id: pasta.id,
                  nomeAtual: pasta.nome,
                ),
          onLongPress: renomeando
              ? null
              : () => _abrirMenuContexto(
                  _centroDoItem(gridContext),
                  tipo: _TipoItem.pasta,
                  id: pasta.id,
                  nomeAtual: pasta.nome,
                ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder, size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: renomeando
                      ? _campoRenomeacao(pasta.id, pasta.nome)
                      : Text(
                          pasta.nome,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: _botaoMenu(
            tipo: _TipoItem.pasta,
            id: pasta.id,
            nomeAtual: pasta.nome,
          ),
        ),
      ],
    );
  }

  Widget _buildArquivoItem(BuildContext gridContext, Arquivo arquivo) {
    final renomeando = _renomeandoId == arquivo.id;
    return Stack(
      children: [
        InkWell(
          onTap: renomeando ? null : () => _verVerificacao(arquivo),
          onSecondaryTapDown: renomeando
              ? null
              : (d) => _abrirMenuContexto(
                  d.globalPosition,
                  tipo: _TipoItem.arquivo,
                  id: arquivo.id,
                  nomeAtual: arquivo.nome,
                ),
          onLongPress: renomeando
              ? null
              : () => _abrirMenuContexto(
                  _centroDoItem(gridContext),
                  tipo: _TipoItem.arquivo,
                  id: arquivo.id,
                  nomeAtual: arquivo.nome,
                ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 48,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: renomeando
                      ? _campoRenomeacao(arquivo.id, arquivo.nome)
                      : Text(
                          arquivo.nome,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (!renomeando) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SHA-256',
                    style: AppTheme.tagStyle(
                      color: AppTheme.textDisabled,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: _botaoMenu(
            tipo: _TipoItem.arquivo,
            id: arquivo.id,
            nomeAtual: arquivo.nome,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentoItem(BuildContext gridContext, Documento documento) {
    final tituloExibido = _tituloDoDocumento(documento);
    final renomeando = _renomeandoId == documento.id;
    return Stack(
      children: [
        InkWell(
          onTap: renomeando
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarkdownEditorScreen(
                        projectId: widget.projetoId,
                        documentoId: documento.id,
                      ),
                    ),
                  );
                  await _carregar();
                },
          onSecondaryTapDown: renomeando
              ? null
              : (d) => _abrirMenuContexto(
                  d.globalPosition,
                  tipo: _TipoItem.documento,
                  id: documento.id,
                  nomeAtual: tituloExibido,
                ),
          onLongPress: renomeando
              ? null
              : () => _abrirMenuContexto(
                  _centroDoItem(gridContext),
                  tipo: _TipoItem.documento,
                  id: documento.id,
                  nomeAtual: tituloExibido,
                ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description,
                  size: 48,
                  color: AppTheme.statusInProgress,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: renomeando
                      ? _campoRenomeacao(documento.id, tituloExibido)
                      : Text(
                          tituloExibido,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (!renomeando && documento.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    documento.tags.join(', '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: _botaoMenu(
            tipo: _TipoItem.documento,
            id: documento.id,
            nomeAtual: tituloExibido,
          ),
        ),
      ],
    );
  }
}
