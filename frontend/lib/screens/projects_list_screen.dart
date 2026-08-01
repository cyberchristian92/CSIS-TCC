import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/screens/project_details_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  bool _exportando = false;

  Future<void> _exportarProjeto(WorkspaceProvider provider, Projeto projeto) async {
    setState(() => _exportando = true);
    try {
      final bytes = await provider.exportarProjeto(projeto.id);
      final nomeSeguro = projeto.nome.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_');
      final blob = html.Blob([bytes], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'projeto-$nomeSeguro.zip')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkspaceProvider>().carregarProjetos();
    });
  }

  Future<void> _showNewProjectModal(WorkspaceProvider provider) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool enviando = false;
    String? erro;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Novo Projeto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome do Projeto'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 3,
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
                        if (nameController.text.trim().isEmpty) return;
                        setState(() => enviando = true);
                        try {
                          await provider.criarProjeto(nameController.text.trim(), descricao: descController.text.trim());
                          if (context.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() {
                            enviando = false;
                            erro = e.toString();
                          });
                        }
                      },
                child: enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                      )
                    : const Text('Criar Projeto'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final projetos = provider.projetos.where((p) => p.status != 'ARQUIVADO').toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projetos', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar',
                    onPressed: () => provider.carregarProjetos(),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showNewProjectModal(provider),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo Projeto'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: _buildConteudo(provider, projetos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo(WorkspaceProvider provider, List<Projeto> projetos) {
    if (provider.isLoadingProjetos && projetos.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (provider.erro != null && projetos.isEmpty) {
      return Center(
        child: Text('Erro ao carregar projetos: ${provider.erro}', style: const TextStyle(color: AppTheme.statusRejected)),
      );
    }
    if (projetos.isEmpty) {
      return const Center(
        child: Text('Nenhum projeto ainda. Clique em "Novo Projeto" para começar.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView(
      children: [
        _buildTableHeader(),
        ...projetos.map((p) => Column(
              children: [
                _buildTableRow(context, p, provider),
                const Divider(height: 1),
              ],
            )),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('NOME', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('PRAZO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('MISSÕES', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          SizedBox(width: 88),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Projeto projeto, WorkspaceProvider provider) {
    Color statusColor;
    switch (projeto.status) {
      case 'CONCLUIDO':
        statusColor = AppTheme.statusApproved;
        break;
      case 'ARQUIVADO':
        statusColor = AppTheme.statusArchived;
        break;
      default:
        statusColor = AppTheme.statusInProgress;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: projeto.id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(projeto.nome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(projeto.status, style: AppTheme.tagStyle(color: statusColor)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                projeto.prazo != null ? '${projeto.prazo!.day}/${projeto.prazo!.month}/${projeto.prazo!.year}' : '—',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(flex: 1, child: Text('${projeto.missoes.length} mis.', style: const TextStyle(fontSize: 13))),
            SizedBox(
              width: 88,
              child: Row(
                children: [
                  IconButton(
                    icon: _exportando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                        : const Icon(Icons.download_outlined, color: AppTheme.textSecondary, size: 20),
                    tooltip: 'Exportar Projeto (dados + arquivos + auditoria)',
                    onPressed: _exportando ? null : () => _exportarProjeto(provider, projeto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive_outlined, color: AppTheme.textSecondary, size: 20),
                    tooltip: 'Arquivar Projeto',
                    onPressed: () async {
                      await provider.arquivarProjeto(projeto.id);
                      await provider.carregarProjetos();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
