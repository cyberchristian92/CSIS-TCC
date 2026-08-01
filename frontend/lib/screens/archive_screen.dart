import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/screens/project_details_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WorkspaceProvider>().carregarProjetos());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final arquivados = provider.projetos.where((p) => p.status == 'ARQUIVADO').toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cofre de Arquivamento', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Projetos encerrados ou inativos mantidos por exigência de rastreabilidade.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar', onPressed: () => provider.carregarProjetos()),
            ],
          ),
          const SizedBox(height: 32),
          if (provider.isLoadingProjetos && provider.projetos.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
          else if (arquivados.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined, size: 64, color: AppTheme.border),
                    SizedBox(height: 16),
                    Text('Nenhum projeto arquivado.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
                child: ListView(
                  children: [
                    _buildTableHeader(),
                    ...arquivados.map((p) => Column(
                          children: [
                            _buildTableRow(context, p),
                            const Divider(height: 1),
                          ],
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('NOME', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('PRAZO ORIGINAL', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('MISSÕES', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Projeto projeto) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: projeto.id)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(projeto.nome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
            Expanded(
              flex: 2,
              child: Text(
                projeto.prazo != null ? '${projeto.prazo!.day}/${projeto.prazo!.month}/${projeto.prazo!.year}' : '—',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ),
            Expanded(flex: 1, child: Text('${projeto.missoes.length}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusArchived.withValues(alpha: 0.12),
                    border: Border.all(color: AppTheme.statusArchived),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ARQUIVADO', style: AppTheme.tagStyle(color: AppTheme.statusArchived)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
