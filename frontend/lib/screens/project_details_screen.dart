import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/markdown_editor_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  void _showNewMissionModal(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedAssignee;

    showDialog(
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
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição ou Critérios de Aceite'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Atribuir para'),
                  value: selectedAssignee,
                  items: appState.resources.map((r) {
                    return DropdownMenuItem(value: r.name, child: Text(r.name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedAssignee = val),
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
                  if (titleController.text.isNotEmpty && selectedAssignee != null) {
                    final mission = Mission(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descriptionController.text,
                      assignee: selectedAssignee!,
                      deadline: DateTime.now().add(const Duration(days: 7)),
                    );
                    appState.addMission(widget.projectId, mission);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Criar Missão'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showNewSubmissionModal(BuildContext context, AppState appState, Mission mission) {
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Entregar: ${mission.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Descreva o que foi feito ou cole o link da evidência:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Laudo escrito em...',
                  border: OutlineInputBorder(),
                ),
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
                if (contentController.text.isNotEmpty) {
                  final sub = Submission(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    missionId: mission.id,
                    authorName: 'Admin', // Simulado
                    submittedAt: DateTime.now(),
                    content: contentController.text,
                  );
                  appState.addSubmission(widget.projectId, mission.id, sub);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Enviar para Revisão'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final project = appState.projects.firstWhere((p) => p.id == widget.projectId);

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
              Text(project.name, style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
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
            _buildOverviewTab(project),
            _buildMissionsTab(context, appState, project),
            _buildFilesTab(context, appState, project),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Project project) {
    final totalMissions = project.missions.length;
    final completedMissions = project.missions.where((m) => m.status == 'Concluída').length;
    final progress = totalMissions == 0 ? 0.0 : (completedMissions / totalMissions);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${project.type} • ${project.area}', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Progresso do Projeto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.border,
                    color: AppTheme.primary,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text('$completedMissions de $totalMissions missões concluídas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab(BuildContext context, AppState appState, Project project) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showNewMissionModal(context, appState),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Missão'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn('A Fazer', project.missions.where((m) => m.status == 'A Fazer').toList(), appState, project),
                const SizedBox(width: 16),
                _buildKanbanColumn('Em Andamento', project.missions.where((m) => m.status == 'Em Andamento').toList(), appState, project),
                const SizedBox(width: 16),
                _buildKanbanColumn('Em Revisão', project.missions.where((m) => m.status == 'Em Revisão').toList(), appState, project),
                const SizedBox(width: 16),
                _buildKanbanColumn('Concluída', project.missions.where((m) => m.status == 'Concluída').toList(), appState, project),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<Mission> missions, AppState appState, Project project) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(12)),
                    child: Text('${missions.length}', style: const TextStyle(fontSize: 12)),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: missions.map((m) => _buildMissionCard(m, appState, project)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(Mission mission, AppState appState, Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(mission.assignee[0], style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text(mission.assignee.split(' ')[0], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                Text('${mission.deadline.day}/${mission.deadline.month}', style: const TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
              ],
            ),
            if (mission.status == 'A Fazer' || mission.status == 'Em Andamento') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (mission.status == 'A Fazer') {
                      appState.updateMissionStatus(project.id, mission.id, 'Em Andamento');
                    } else {
                      _showNewSubmissionModal(context, appState, mission);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(mission.status == 'A Fazer' ? 'Iniciar' : 'Fazer Entrega', style: const TextStyle(fontSize: 11)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFilesTab(BuildContext context, AppState appState, Project project) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gestor de Arquivos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final newFile = ProjectFile(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: 'Evidencia_${DateTime.now().millisecondsSinceEpoch}.png',
                        type: 'image',
                        createdAt: DateTime.now(),
                      );
                      appState.addFileToProject(project.id, newFile);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload simulado com sucesso!')));
                    },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Fazer Upload'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: project.id)),
                      );
                    },
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('Novo Arquivo .md'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: project.files.isEmpty
                  ? const Center(
                      child: Text('Nenhum arquivo encontrado. Faça o upload de evidências ou crie um laudo.', style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: project.files.length,
                      itemBuilder: (context, index) {
                        final file = project.files[index];
                        return _buildFileItem(context, file);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, ProjectFile file) {
    IconData iconData;
    Color iconColor;

    switch (file.type) {
      case 'folder':
        iconData = Icons.folder;
        iconColor = Colors.amber;
        break;
      case 'md':
        iconData = Icons.description;
        iconColor = Colors.blueAccent;
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = AppTheme.textSecondary;
    }

    return InkWell(
      onTap: () {
        if (file.type == 'md') {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MarkdownEditorScreen(projectId: widget.projectId, fileId: file.id)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visualizador ainda não implementado.')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                file.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
