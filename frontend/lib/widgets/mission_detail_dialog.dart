import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/screens/markdown_editor_screen.dart';

/// Modal de detalhe da missão — estilo "card" do Trello: título, descrição,
/// responsável, histórico de entregas/revisões e anexos (arquivos e
/// documentos vinculados especificamente a esta missão).
Future<void> showMissionDetailDialog(
  BuildContext context,
  Missao missao, {
  required Future<void> Function() onChanged,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppTheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 780),
        child: _MissionDetailPanel(missao: missao, onChanged: onChanged),
      ),
    ),
  );
}

class _MissionDetailPanel extends StatefulWidget {
  final Missao missao;
  final Future<void> Function() onChanged;

  const _MissionDetailPanel({required this.missao, required this.onChanged});

  @override
  State<_MissionDetailPanel> createState() => _MissionDetailPanelState();
}

class _MissionDetailPanelState extends State<_MissionDetailPanel> {
  late Missao _missao;
  bool _carregando = true;
  List<Entrega> _entregas = [];
  List<Arquivo> _arquivos = [];
  List<Documento> _documentos = [];
  List<ChecklistItem> _checklist = [];
  List<ComentarioMissao> _comentarios = [];
  final Map<String, List<Revisao>> _revisoesPorEntrega = {};

  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _itemChecklistController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _missao = widget.missao;
    _carregar();
  }

  @override
  void dispose() {
    _tagController.dispose();
    _itemChecklistController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    final missaoAtualizada = await provider.buscarMissao(_missao.id);
    final entregas = await provider.listarEntregasDaMissao(_missao.id);
    final arquivos = await provider.listarArquivosDoProjeto(_missao.projetoId, missaoId: _missao.id);
    final documentos = await provider.listarDocumentosDoProjeto(_missao.projetoId, missaoId: _missao.id);
    final checklist = await provider.listarChecklist(_missao.id);
    final comentarios = await provider.listarComentarios(_missao.id);
    for (final entrega in entregas) {
      _revisoesPorEntrega[entrega.id] = await provider.listarRevisoesDaEntrega(entrega.id);
    }
    if (!mounted) return;
    setState(() {
      _missao = missaoAtualizada;
      _entregas = entregas;
      _arquivos = arquivos;
      _documentos = documentos;
      _checklist = checklist;
      _comentarios = comentarios;
      _carregando = false;
    });
  }

  Future<void> _adicionarTag(WorkspaceProvider provider, String tag) async {
    final normalizada = tag.trim();
    if (normalizada.isEmpty || _missao.tags.contains(normalizada)) return;
    _tagController.clear();
    await provider.atualizarTagsMissao(_missao.id, [..._missao.tags, normalizada]);
    await _recarregarENotificar();
  }

  Future<void> _removerTag(WorkspaceProvider provider, String tag) async {
    await provider.atualizarTagsMissao(_missao.id, _missao.tags.where((t) => t != tag).toList());
    await _recarregarENotificar();
  }

  Future<void> _adicionarItemChecklist(WorkspaceProvider provider) async {
    final texto = _itemChecklistController.text.trim();
    if (texto.isEmpty) return;
    _itemChecklistController.clear();
    await provider.criarItemChecklist(_missao.id, texto);
    await _recarregarENotificar();
  }

  Future<void> _alternarItem(WorkspaceProvider provider, ChecklistItem item) async {
    await provider.alternarItemChecklist(item.id, !item.concluido);
    await _recarregarENotificar();
  }

  Future<void> _removerItemChecklist(WorkspaceProvider provider, ChecklistItem item) async {
    await provider.removerItemChecklist(item.id);
    await _recarregarENotificar();
  }

  Future<void> _postarComentario(WorkspaceProvider provider) async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty) return;
    _comentarioController.clear();
    await provider.criarComentario(_missao.id, texto);
    await _recarregarENotificar();
  }

  Future<void> _removerComentario(WorkspaceProvider provider, ComentarioMissao comentario) async {
    await provider.removerComentario(comentario.id);
    await _recarregarENotificar();
  }

  Future<void> _recarregarENotificar() async {
    await _carregar();
    await widget.onChanged();
  }

  Future<void> _atribuir(WorkspaceProvider provider) async {
    await provider.carregarUsuarios();
    String? responsavelId = _missao.responsavelId;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Atribuir responsável'),
          content: DropdownButtonFormField<String>(
            initialValue: responsavelId,
            decoration: const InputDecoration(labelText: 'Responsável'),
            items: provider.usuarios.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))).toList(),
            onChanged: (val) => setState(() => responsavelId = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: responsavelId == null
                  ? null
                  : () async {
                      await provider.atribuirMissao(_missao.id, responsavelId!);
                      if (context.mounted) Navigator.pop(ctx);
                      await _recarregarENotificar();
                    },
              child: const Text('Atribuir'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _iniciar(WorkspaceProvider provider) async {
    await provider.iniciarMissao(_missao.id);
    await _recarregarENotificar();
  }

  Future<void> _fazerEntrega(WorkspaceProvider provider) async {
    final controller = TextEditingController();
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Fazer Entrega'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Descreva o que foi feito ou cole o laudo parcial...', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setState(() => enviando = true);
                      await provider.criarEntrega(_missao.id, conteudo: controller.text.trim());
                      if (context.mounted) Navigator.pop(ctx);
                      await _recarregarENotificar();
                    },
              child: const Text('Enviar para Revisão'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _revisar(WorkspaceProvider provider, Entrega entrega) async {
    final controller = TextEditingController();
    bool enviando = false;
    String? erro;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        Future<void> revisar(String status) async {
          setState(() => enviando = true);
          try {
            await provider.criarRevisao(entrega.id, status: status, comentario: controller.text.trim());
            if (context.mounted) Navigator.pop(ctx);
            await _recarregarENotificar();
          } catch (e) {
            setState(() {
              erro = e.toString();
              enviando = false;
            });
          }
        }

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Revisar Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Comentário...', border: OutlineInputBorder())),
              if (erro != null) ...[
                const SizedBox(height: 8),
                Text(erro!, style: const TextStyle(color: AppTheme.statusRejected, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusInReview, foregroundColor: Colors.black),
              onPressed: enviando ? null : () => revisar('REJEITADO'),
              child: const Text('Solicitar Ajustes'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusApproved),
              onPressed: enviando ? null : () => revisar('APROVADO'),
              child: const Text('Aprovar'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _fazerUpload(WorkspaceProvider provider) async {
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    if (resultado == null || resultado.files.isEmpty || resultado.files.single.bytes == null) return;
    await provider.uploadArquivo(_missao.projetoId, bytes: resultado.files.single.bytes!, nomeArquivo: resultado.files.single.name, missaoId: _missao.id);
    await _recarregarENotificar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final auth = context.watch<AuthProvider>();
    final ehResponsavel = _missao.responsavelId != null && _missao.responsavelId == auth.currentUser?.id;
    final podeGerenciar = auth.isAdmin || auth.isLider;
    // Coordenador e Revisor têm acesso a tudo no quadro (mover/iniciar/entregar
    // em nome de qualquer missão); Colaborador só na própria. A trava de SoD
    // do backend continua impedindo revisor de aprovar a própria entrega.
    final gerenciaTudo = auth.isAdmin || auth.isLider || auth.isRevisor;
    final podeMovimentar = ehResponsavel || gerenciaTudo;
    final podeRevisar = auth.isAdmin || auth.isLider || auth.isRevisor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
          child: Row(
            children: [
              Expanded(child: Text(_missao.titulo, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.primary), borderRadius: BorderRadius.circular(4)),
                        child: Text(missaoStatusLabel(_missao.status), style: AppTheme.tagStyle()),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._missao.tags.map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 11)),
                                onDeleted: () => _removerTag(provider, tag),
                                backgroundColor: AppTheme.surfaceRaised,
                                visualDensity: VisualDensity.compact,
                              )),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(hintText: '+ tag', border: InputBorder.none, isDense: true),
                              style: const TextStyle(fontSize: 12),
                              onSubmitted: (v) => _adicionarTag(provider, v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_missao.descricao != null && _missao.descricao!.isNotEmpty) ...[
                        Text(_missao.descricao!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                      ],
                      if (_missao.criterioAceite != null && _missao.criterioAceite!.isNotEmpty) ...[
                        Text('Critério de aceite', style: Theme.of(context).textTheme.bodySmall),
                        Text(_missao.criterioAceite!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(_missao.responsavelNome ?? 'Sem responsável', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                          if (podeGerenciar) TextButton(onPressed: () => _atribuir(provider), child: const Text('Atribuir', style: TextStyle(fontSize: 12))),
                          if (_missao.prazo != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_outlined, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text('${_missao.prazo!.day}/${_missao.prazo!.month}/${_missao.prazo!.year}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (podeMovimentar && _missao.status == MissaoStatus.pendente)
                            ElevatedButton.icon(onPressed: () => _iniciar(provider), icon: const Icon(Icons.play_arrow, size: 16), label: const Text('Iniciar')),
                          if (podeMovimentar && _missao.status == MissaoStatus.rejeitada)
                            OutlinedButton.icon(onPressed: () => _iniciar(provider), icon: const Icon(Icons.replay, size: 16), label: const Text('Retomar')),
                          if (podeMovimentar && (_missao.status == MissaoStatus.emAndamento || _missao.status == MissaoStatus.rejeitada))
                            ElevatedButton.icon(onPressed: () => _fazerEntrega(provider), icon: const Icon(Icons.send, size: 16), label: const Text('Fazer Entrega')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildChecklistSection(provider),
                      const SizedBox(height: 24),
                      Text('Entregas e Revisões', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (_entregas.isEmpty)
                        const Text('Nenhuma entrega ainda.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                      else
                        ..._entregas.map((entrega) => _buildEntregaCard(entrega, podeRevisar, provider)),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text('Anexos desta missão', style: Theme.of(context).textTheme.titleSmall),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(onPressed: () => _fazerUpload(provider), icon: const Icon(Icons.upload_file, size: 16), label: const Text('Upload')),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: _missao.projetoId, missaoId: _missao.id)));
                                  await _recarregarENotificar();
                                },
                                icon: const Icon(Icons.note_add, size: 16),
                                label: const Text('Novo Documento'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_arquivos.isEmpty && _documentos.isEmpty)
                        const Text('Nenhum anexo ainda.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ..._arquivos.map((a) => _buildAnexoChip(icon: Icons.insert_drive_file, label: a.nome, color: AppTheme.primary)),
                            ..._documentos.map((d) => _buildAnexoChip(
                                  icon: Icons.description,
                                  label: d.conteudo.split('\n').first.replaceAll('#', '').trim().isEmpty ? 'Documento' : d.conteudo.split('\n').first.replaceAll('#', '').trim(),
                                  color: AppTheme.statusInProgress,
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: _missao.projetoId, documentoId: d.id)));
                                    await _recarregarENotificar();
                                  },
                                )),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildComentariosSection(provider, auth),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(WorkspaceProvider provider) {
    final total = _checklist.length;
    final concluidos = _checklist.where((i) => i.concluido).length;
    final progresso = total == 0 ? 0.0 : concluidos / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Checklist', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 12),
            if (total > 0)
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: LinearProgressIndicator(value: progresso, backgroundColor: AppTheme.border, color: AppTheme.primary, minHeight: 6)),
                    const SizedBox(width: 8),
                    Text('$concluidos/$total', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._checklist.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: item.concluido,
                    activeColor: AppTheme.primary,
                    onChanged: (_) => _alternarItem(provider, item),
                  ),
                  Expanded(
                    child: Text(
                      item.texto,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.concluido ? AppTheme.textDisabled : AppTheme.textMain,
                        decoration: item.concluido ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: AppTheme.textDisabled),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _removerItemChecklist(provider, item),
                  ),
                ],
              ),
            )),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _itemChecklistController,
                decoration: const InputDecoration(hintText: '+ adicionar item...', border: InputBorder.none, isDense: true),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => _adicionarItemChecklist(provider),
              ),
            ),
            IconButton(icon: const Icon(Icons.add, size: 18, color: AppTheme.primary), onPressed: () => _adicionarItemChecklist(provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildComentariosSection(WorkspaceProvider provider, AuthProvider auth) {
    final podeGerenciar = auth.isAdmin || auth.isLider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comentários', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_comentarios.isEmpty) const Text('Nenhum comentário ainda.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ..._comentarios.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text((c.autorNome?.isNotEmpty ?? false) ? c.autorNome![0] : '?', style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.autorNome ?? 'Alguém', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(c.texto, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (podeGerenciar || c.autorId == auth.currentUser?.id)
                    IconButton(icon: const Icon(Icons.close, size: 14, color: AppTheme.textDisabled), visualDensity: VisualDensity.compact, onPressed: () => _removerComentario(provider, c)),
                ],
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _comentarioController,
                decoration: const InputDecoration(hintText: 'Escreva um comentário...', border: OutlineInputBorder(), isDense: true),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => _postarComentario(provider),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.send, size: 18, color: AppTheme.primary), onPressed: () => _postarComentario(provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildEntregaCard(Entrega entrega, bool podeRevisar, WorkspaceProvider provider) {
    final revisoes = _revisoesPorEntrega[entrega.id] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Entrega de ${entrega.autorNome ?? "desconhecido"}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(entrega.status, style: AppTheme.tagStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
          if (entrega.conteudo != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(entrega.conteudo!, style: const TextStyle(fontSize: 13))),
          ...revisoes.map((r) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${r.status}${r.comentario != null && r.comentario!.isNotEmpty ? ": ${r.comentario}" : ""}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              )),
          if (podeRevisar && entrega.status == 'EM_REVISAO') ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => _revisar(provider, entrega), child: const Text('Revisar', style: TextStyle(fontSize: 12))),
          ],
        ],
      ),
    );
  }

  Widget _buildAnexoChip({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
