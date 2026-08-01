import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAudit;

  const DashboardScreen({super.key, this.onNavigateToAudit});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _carregando = true;
  int _projetosAtivos = 0;
  int _projetosAtrasados = 0;
  int _missoesPendentes = 0;
  int _minhasMissoes = 0;
  List<Projeto> _recentes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final provider = context.read<WorkspaceProvider>();
    final auth = context.read<AuthProvider>();

    await provider.carregarProjetos();
    final ativos = provider.projetos.where((p) => p.status != 'ARQUIVADO').toList();

    int atrasados = 0;
    int pendentes = 0;
    int minhas = 0;
    for (final resumo in ativos) {
      if (resumo.prazo != null && resumo.prazo!.isBefore(DateTime.now()) && resumo.status != 'CONCLUIDO') {
        atrasados++;
      }
      final detalhado = await provider.buscarProjeto(resumo.id);
      for (final missao in detalhado.missoes) {
        if (missao.status != MissaoStatus.aprovada) pendentes++;
        if (missao.responsavelId == auth.currentUser?.id &&
            missao.status != MissaoStatus.aprovada &&
            missao.status != MissaoStatus.rejeitada) {
          minhas++;
        }
      }
    }

    if (auth.isAdmin || auth.isLider) {
      await provider.carregarAuditoria();
    }

    if (!mounted) return;
    setState(() {
      _projetosAtivos = ativos.length;
      _projetosAtrasados = atrasados;
      _missoesPendentes = pendentes;
      _minhasMissoes = minhas;
      _recentes = ativos.reversed.take(3).toList();
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<WorkspaceProvider>();
    final ehGestor = auth.isAdmin || auth.isLider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Painel Geral', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Olá, ${auth.currentUser?.nome ?? ''} — visão geral da operação',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          if (_carregando)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppTheme.primary)))
          else ...[
            Row(
              children: [
                Expanded(child: _buildKpiCard('Projetos Ativos', '$_projetosAtivos', AppTheme.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard('Projetos Atrasados', '$_projetosAtrasados', AppTheme.statusRejected)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard('Missões Pendentes', '$_missoesPendentes', AppTheme.statusInReview)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard('Minhas Missões', '$_minhasMissoes', AppTheme.statusInProgress)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: ehGestor ? 2 : 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Últimos Projetos', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 16),
                          if (_recentes.isEmpty)
                            const Text('Nenhum projeto encontrado.', style: TextStyle(color: AppTheme.textSecondary)),
                          ..._recentes.map((p) => _buildProjectRow(p.nome, p.status)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (ehGestor) ...[
                  const SizedBox(width: 24),
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
                            if (provider.auditoria.isEmpty)
                              const Text('Sem registros recentes', style: TextStyle(color: AppTheme.textSecondary)),
                            ...provider.auditoria.take(4).map(
                                  (log) => _buildAuditRow(
                                    log.userNome ?? 'Sistema',
                                    log.acao,
                                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: widget.onNavigateToAudit,
                              child: const Text('Ver auditoria completa'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectRow(String name, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$user — $action', style: const TextStyle(fontSize: 13)),
                Text(time, style: const TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
