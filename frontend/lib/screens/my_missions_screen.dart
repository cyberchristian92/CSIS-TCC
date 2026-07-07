import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/project_details_screen.dart';

class MyMissionsScreen extends StatelessWidget {
  const MyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Pegar todas as missões onde o assignee sou eu ("Admin" no nosso mock)
    // E associá-las ao seu respectivo projeto para podermos mostrar a origem.
    final List<Map<String, dynamic>> myMissions = [];
    
    for (var project in appState.projects) {
      for (var mission in project.missions) {
        if (mission.assignee == 'Admin' || mission.assignee.contains('Admin')) {
          myMissions.add({
            'project': project,
            'mission': mission,
          });
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minhas Missões',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tarefas atribuídas a você em todos os projetos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn(
                  'A Fazer', 
                  myMissions.where((m) => m['mission'].status == 'A Fazer').toList(),
                  context
                ),
                const SizedBox(width: 16),
                _buildKanbanColumn(
                  'Em Andamento', 
                  myMissions.where((m) => m['mission'].status == 'Em Andamento').toList(),
                  context
                ),
                const SizedBox(width: 16),
                _buildKanbanColumn(
                  'Em Revisão', 
                  myMissions.where((m) => m['mission'].status == 'Em Revisão').toList(),
                  context
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, List<Map<String, dynamic>> missions, BuildContext context) {
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
                children: missions.map((m) => _buildMissionCard(m, context)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> data, BuildContext context) {
    final Project project = data['project'];
    final Mission mission = data['mission'];

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
            const SizedBox(height: 4),
            Text(project.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 14, color: AppTheme.textDisabled),
                  ],
                ),
                Text('${mission.deadline.day}/${mission.deadline.month}', style: const TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProjectDetailsScreen(projectId: project.id)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ir para Projeto', style: TextStyle(fontSize: 11)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
