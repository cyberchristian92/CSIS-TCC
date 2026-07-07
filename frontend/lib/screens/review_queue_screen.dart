import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  void _showReviewModal(BuildContext context, AppState appState, Project project, Mission mission, Submission submission) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Revisar Entrega: ${mission.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Autor: ${submission.authorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                child: Text(submission.content, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 24),
              const Text('Seu Parecer', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escreva um comentário (obrigatório para pedir ajustes)...',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusPending, foregroundColor: Colors.black),
              onPressed: () {
                appState.reviewSubmission(project.id, mission.id, submission.id, 'Ajustes');
                Navigator.pop(ctx);
              },
              child: const Text('Solicitar Ajustes'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusApproved),
              onPressed: () {
                appState.reviewSubmission(project.id, mission.id, submission.id, 'Aprovada');
                Navigator.pop(ctx);
              },
              child: const Text('Aprovar Entrega'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Coleta todas as entregas com status 'Pendente' (que significa que aguardam revisão)
    final List<Map<String, dynamic>> pendings = [];
    
    for (var project in appState.projects) {
      for (var mission in project.missions) {
        for (var sub in mission.submissions) {
          if (sub.status == 'Pendente') {
            pendings.add({
              'project': project,
              'mission': mission,
              'submission': sub,
            });
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fila de Revisão',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Auditoria de Qualidade - Entregas pendentes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: pendings.isEmpty 
              ? const Center(child: Text('Nenhuma entrega aguardando revisão.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView(
                  children: [
                    _buildTableHeader(),
                    ...pendings.map((p) {
                      return Column(
                        children: [
                          _buildTableRow(context, appState, p),
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
          Expanded(flex: 3, child: Text('MISSÃO / PROJETO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('AUTOR', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('TEMPO NA FILA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('AÇÃO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AppState appState, Map<String, dynamic> data) {
    final Project project = data['project'];
    final Mission mission = data['mission'];
    final Submission submission = data['submission'];

    // Simulação do tempo na fila
    final diff = DateTime.now().difference(submission.submittedAt);
    String timeStr = '${diff.inHours}h';
    if (diff.inHours == 0) timeStr = '${diff.inMinutes}m';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(project.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(submission.authorName[0], style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(submission.authorName, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            )
          ),
          Expanded(flex: 1, child: Text(timeStr, style: const TextStyle(fontSize: 14, color: AppTheme.statusPending, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _showReviewModal(context, appState, project, mission, submission),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Revisar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
