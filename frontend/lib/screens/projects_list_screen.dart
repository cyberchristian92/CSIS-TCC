import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/project_details_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  void _showNewProjectModal(AppState appState) {
    final nameController = TextEditingController();
    String? selectedType;
    String? selectedArea;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Novo Projeto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Projeto'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Área'),
                value: selectedArea,
                items: appState.areas.map((a) {
                  return DropdownMenuItem(value: a.name, child: Text(a.name));
                }).toList(),
                onChanged: (val) => setState(() => selectedArea = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de Projeto'),
                value: selectedType,
                items: appState.projectTypes.map((pt) {
                  return DropdownMenuItem(value: pt.name, child: Text(pt.name));
                }).toList(),
                onChanged: (val) => setState(() => selectedType = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedType != null && selectedArea != null) {
                  final newProject = Project(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    type: selectedType!,
                    area: selectedArea!,
                    status: 'Aberto',
                    deadline: DateTime.now().add(const Duration(days: 15)),
                  );
                  appState.addProject(newProject);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Criar Projeto'),
            ),
          ],
        );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final projects = appState.projects.where((p) => p.status != 'Arquivado').toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projetos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewProjectModal(appState),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Projeto'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Barra de Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildFilterDropdown('Área: Todas'),
                const SizedBox(width: 16),
                _buildFilterDropdown('Tipo: Todos'),
                const SizedBox(width: 16),
                _buildFilterDropdown('Status: Ativos'),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textDisabled),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tabela de Projetos
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
                  ...projects.map((p) {
                    return Column(
                      children: [
                        _buildTableRow(context, p, appState),
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

  Widget _buildFilterDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16),
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
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('PRAZO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('MISSÕES', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Project project, AppState appState) {
    Color statusColor = AppTheme.statusPending;
    if (project.status == 'Concluído') statusColor = AppTheme.statusApproved;
    if (project.status == 'Em Andamento') statusColor = AppTheme.statusInProgress;
    if (project.status == 'Aberto') statusColor = AppTheme.primary;

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
            Expanded(flex: 2, child: Text(project.area, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            Expanded(flex: 1, child: Text('${project.deadline.day}/${project.deadline.month}/${project.deadline.year}', style: const TextStyle(fontSize: 13))),
            Expanded(flex: 1, child: Text('${project.missions.length} mis.', style: const TextStyle(fontSize: 13))),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.archive_outlined, color: AppTheme.textSecondary, size: 20),
                tooltip: 'Arquivar Projeto',
                onPressed: () {
                  appState.archiveProject(project.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
