import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    final unarchivedProjects = appState.projects.where((p) => p.status != 'Arquivado').toList();
    final activeProjectsCount = unarchivedProjects.length;
    
    int delayedProjectsCount = 0;
    int pendingMissionsCount = 0;
    
    for (var p in unarchivedProjects) {
      if (p.deadline.isBefore(DateTime.now()) && p.status != 'Concluído') {
        delayedProjectsCount++;
      }
      for (var m in p.missions) {
        if (m.status != 'Concluída') pendingMissionsCount++;
      }
    }
    
    final recentProjects = unarchivedProjects.reversed.take(3).toList();
    final recentLogs = appState.auditLogs.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Painel Geral',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Visão administrativa da operação',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // 4 KPIs grandes
          Row(
            children: [
              Expanded(child: _buildKpiCard('Projetos Ativos', '$activeProjectsCount', AppTheme.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard('Projetos Atrasados', '$delayedProjectsCount', AppTheme.statusRejected)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard('Missões Pendentes', '$pendingMissionsCount', AppTheme.statusPending)),
              const SizedBox(width: 16),
              Expanded(child: _buildKpiCard('Usuários', '${appState.resources.length}', AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 32),
          
          // 2 Colunas: Últimos Projetos e Auditoria Recente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Últimos projetos
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Últimos Projetos', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 16),
                        if (recentProjects.isEmpty)
                          const Text('Nenhum projeto encontrado.', style: TextStyle(color: AppTheme.textSecondary)),
                        ...recentProjects.map((p) => _buildProjectRow(p.name, p.type, p.status)).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Auditoria
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auditoria (Recentes)', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 16),
                        ...recentLogs.map((log) => _buildAuditRow(log.user, log.action, '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}')).toList(),
                        if (recentLogs.isEmpty)
                          const Text('Sem registros recentes', style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                          child: const Text('Ver auditoria completa'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectRow(String name, String type, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(type, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(status, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String user, String action, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(color: AppTheme.border, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$user $action', style: const TextStyle(fontSize: 13)),
                Text(time, style: const TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
