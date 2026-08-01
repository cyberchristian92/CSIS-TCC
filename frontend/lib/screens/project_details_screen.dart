import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/widgets/mission_kanban_board.dart';
import 'package:frontend/widgets/file_browser.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Projeto? _projeto;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    try {
      final projeto = await provider.buscarProjeto(widget.projectId);
      if (!mounted) return;
      setState(() {
        _projeto = projeto;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _showNewMissionModal(BuildContext context, WorkspaceProvider provider) async {
    final titleController = TextEditingController();
    final criterioController = TextEditingController();
    String? responsavelId;
    bool enviando = false;
    String? erro;

    await provider.carregarUsuarios();

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Nova Missão'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título da Missão'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: criterioController,
                  decoration: const InputDecoration(labelText: 'Critério de aceite (opcional)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Atribuir para (opcional)'),
                  initialValue: responsavelId,
                  items: provider.usuarios
                      .map((u) => DropdownMenuItem(value: u.id, child: Text('${u.nome} (${u.papelGlobal})')))
                      .toList(),
                  onChanged: (val) => setState(() => responsavelId = val),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 12),
                  Text(erro!, style: const TextStyle(color: AppTheme.statusRejected, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty) return;
                        setState(() => enviando = true);
                        try {
                          final missao = await provider.criarMissao(
                            widget.projectId,
                            titulo: titleController.text.trim(),
                            criterioAceite: criterioController.text.trim(),
                          );
                          if (responsavelId != null) {
                            await provider.atribuirMissao(missao.id, responsavelId!);
                          }
                          if (context.mounted) Navigator.pop(ctx);
                          await _carregar();
                        } catch (e) {
                          setState(() {
                            enviando = false;
                            erro = e.toString();
                          });
                        }
                      },
                child: enviando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                    : const Text('Criar Missão'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    if (_erro != null || _projeto == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.surface),
        body: Center(child: Text('Erro ao carregar projeto: $_erro', style: const TextStyle(color: AppTheme.statusRejected))),
      );
    }

    final provider = context.watch<WorkspaceProvider>();
    final projeto = _projeto!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textSecondary),
          title: Row(
            children: [
              const Text('Projetos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const Icon(Icons.chevron_right, color: AppTheme.textDisabled, size: 18),
              Text(projeto.nome, style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Visão Geral'),
              Tab(text: 'Missões (Kanban)'),
              Tab(text: 'Arquivos e Documentos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(projeto),
            _buildMissionsTab(context, provider, projeto),
            Padding(padding: const EdgeInsets.all(24.0), child: FileBrowser(projetoId: widget.projectId)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Projeto projeto) {
    final total = projeto.missoes.length;
    final aprovadas = projeto.missoes.where((m) => m.status == MissaoStatus.aprovada).length;
    final progress = total == 0 ? 0.0 : (aprovadas / total);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(projeto.nome, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(projeto.descricao ?? 'Sem descrição', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progresso do Projeto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress, backgroundColor: AppTheme.border, color: AppTheme.primary, minHeight: 8),
                  const SizedBox(height: 8),
                  Text('$aprovadas de $total missões aprovadas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab(BuildContext context, WorkspaceProvider provider, Projeto projeto) {
    final auth = context.watch<AuthProvider>();
    final podeGerenciar = auth.isAdmin || auth.isLider;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (podeGerenciar)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showNewMissionModal(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nova Missão'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(child: MissionKanbanBoard(missoes: projeto.missoes, onChanged: _carregar)),
        ],
      ),
    );
  }
}
