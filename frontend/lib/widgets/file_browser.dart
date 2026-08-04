import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/screens/markdown_editor_screen.dart';

/// Navegador de pastas estilo Drive para os arquivos e documentos de um
/// projeto: breadcrumb, subpastas, upload e criação de documento sempre
/// dentro da pasta atual.
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

  String? get _pastaAtualId => _pilha.isEmpty ? null : _pilha.last.id;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    final pastas = await provider.listarPastas(widget.projetoId, pastaPaiId: _pastaAtualId);
    final arquivos = await provider.listarArquivosDoProjeto(widget.projetoId, pastaId: _pastaAtualId ?? 'raiz');
    final documentos = await provider.listarDocumentosDoProjeto(widget.projetoId, pastaId: _pastaAtualId ?? 'raiz');
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
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nome da pasta'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final provider = context.read<WorkspaceProvider>();
              await provider.criarPasta(widget.projetoId, controller.text.trim(), pastaPaiId: _pastaAtualId);
              if (context.mounted) Navigator.pop(ctx);
              await _carregar();
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _removerPasta(Pasta pasta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Remover "${pasta.nome}"?'),
        content: const Text('Os arquivos e documentos dentro dela voltam para a pasta anterior (não são apagados).', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusRejected),
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
    if (resultado == null || resultado.files.isEmpty || resultado.files.single.bytes == null) return;
    if (!mounted) return;
    final provider = context.read<WorkspaceProvider>();
    await provider.uploadArquivo(
      widget.projetoId,
      bytes: resultado.files.single.bytes!,
      nomeArquivo: resultado.files.single.name,
      pastaId: _pastaAtualId ?? 'raiz',
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo enviado — hash SHA-256 calculado.')));
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
            SelectableText(arquivo.hashSha256, style: AppTheme.monoTextStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(resultado['integro'] == true ? Icons.verified : Icons.error, color: resultado['integro'] == true ? AppTheme.statusApproved : AppTheme.statusRejected, size: 18),
                const SizedBox(width: 8),
                Text(resultado['integro'] == true ? 'Integridade verificada' : 'Hash não confere!', style: TextStyle(color: resultado['integro'] == true ? AppTheme.statusApproved : AppTheme.statusRejected)),
              ],
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botoes = [
      OutlinedButton.icon(onPressed: _novaPasta, icon: const Icon(Icons.create_new_folder_outlined, size: 16), label: const Text('Nova Pasta')),
      OutlinedButton.icon(onPressed: _fazerUpload, icon: const Icon(Icons.upload_file, size: 16), label: const Text('Upload')),
      ElevatedButton.icon(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: widget.projetoId, pastaId: _pastaAtualId ?? 'raiz')));
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
            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
            child: _carregando
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : (_pastas.isEmpty && _arquivos.isEmpty && _documentos.isEmpty)
                    ? const Center(child: Text('Pasta vazia. Crie uma subpasta, faça upload ou adicione um documento.', style: TextStyle(color: AppTheme.textSecondary)))
                    : GridView.builder(
                        // Extensão máxima em vez de contagem fixa de colunas: reflui
                        // sozinho pro número de colunas certo em qualquer largura
                        // (considera o espaço real do grid, não a tela inteira).
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1),
                        itemCount: _pastas.length + _arquivos.length + _documentos.length,
                        itemBuilder: (context, index) {
                          if (index < _pastas.length) return _buildPastaItem(_pastas[index]);
                          final indexArquivo = index - _pastas.length;
                          if (indexArquivo < _arquivos.length) return _buildArquivoItem(_arquivos[indexArquivo]);
                          return _buildDocumentoItem(_documentos[indexArquivo - _arquivos.length]);
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
          child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.home_outlined, size: 16, color: AppTheme.primary), SizedBox(width: 4), Text('Raiz', style: TextStyle(color: AppTheme.primary, fontSize: 13))]),
        ),
        for (var i = 0; i < _pilha.length; i++) ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textDisabled)),
          InkWell(
            onTap: () => _voltarPara(i),
            child: Text(_pilha[i].nome, style: TextStyle(color: i == _pilha.length - 1 ? AppTheme.textMain : AppTheme.primary, fontSize: 13, fontWeight: i == _pilha.length - 1 ? FontWeight.w600 : FontWeight.normal)),
          ),
        ],
      ],
    );
  }

  Widget _buildPastaItem(Pasta pasta) {
    return InkWell(
      onTap: () => _entrarNaPasta(pasta),
      onLongPress: () => _removerPasta(pasta),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder, size: 48, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(pasta.nome, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildArquivoItem(Arquivo arquivo) {
    return InkWell(
      onTap: () => _verVerificacao(arquivo),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(arquivo.nome, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
            const SizedBox(height: 4),
            Text('SHA-256', style: AppTheme.tagStyle(color: AppTheme.textDisabled, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentoItem(Documento documento) {
    final titulo = documento.conteudo.split('\n').first.replaceAll('#', '').trim();
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: widget.projetoId, documentoId: documento.id)));
        await _carregar();
      },
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 48, color: AppTheme.statusInProgress),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(titulo.isEmpty ? 'Documento sem título' : titulo, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            if (documento.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(documento.tags.join(', '), style: const TextStyle(fontSize: 10, color: AppTheme.textDisabled), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
