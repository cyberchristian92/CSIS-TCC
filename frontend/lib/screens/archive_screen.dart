import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/project_details_screen.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final archivedProjects = appState.projects.where((p) => p.status == 'Arquivado').toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cofre de Arquivamento', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Projetos encerrados ou inativos mantidos por exigência de rastreabilidade.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          
          if (archivedProjects.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.archive_outlined, size: 64, color: AppTheme.border),
                    const SizedBox(height: 16),
                    const Text('Nenhum projeto arquivado.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  children: [
                    _buildTableHeader(),
                    ...archivedProjects.map((p) {
                      return Column(
                        children: [
                          _buildTableRow(context, p),
                          const Divider(height: 1),
                        ],
                      );
                    }).toList(),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('NOME', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('TIPO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('ÁREA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('STATUS ORIGINAL', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Project project) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: project.id)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
            Expanded(flex: 2, child: Text(project.type, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            Expanded(flex: 2, child: Row(
              children: [
                const Icon(Icons.domain, size: 16, color: AppTheme.textDisabled),
                const SizedBox(width: 8),
                Text(project.area, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            )),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusPending.withOpacity(0.1),
                    border: Border.all(color: AppTheme.statusPending),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ARQUIVADO',
                    style: TextStyle(color: AppTheme.statusPending, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
