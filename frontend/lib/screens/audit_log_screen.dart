import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WorkspaceProvider>().carregarAuditoria());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final logs = provider.auditoria;

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
                  Text('Auditoria Global', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Registro inalterável de todas as ações realizadas no sistema.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar', onPressed: () => provider.carregarAuditoria()),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: provider.isLoadingAuditoria && logs.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : logs.isEmpty
                      ? const Center(child: Text('Nenhum registro de auditoria ainda.', style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView(
                          children: [
                            _buildTableHeader(),
                            ...logs.map((log) => Column(
                                  children: [
                                    _buildTableRow(log),
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
          Expanded(flex: 1, child: Text('DATA/HORA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('AÇÃO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('USUÁRIO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('ENTIDADE AFETADA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(LogAuditoria log) {
    final t = log.timestamp;
    final formattedTime =
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(formattedTime, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text(log.acao, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppTheme.textDisabled),
                const SizedBox(width: 8),
                Text(log.userNome ?? 'Sistema', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(log.entidade, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}
