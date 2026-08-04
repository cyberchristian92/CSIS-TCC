import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/widgets/mission_card.dart';
import 'package:frontend/widgets/mission_detail_dialog.dart';

/// Kanban de missões reutilizável (usado no detalhe do projeto e em "Minhas
/// Missões"), com arrastar-e-soltar estilo Trello. Cada transição de coluna
/// é validada contra as mesmas regras de negócio do backend (SoD, quem é o
/// responsável) — quando a solta exige informação adicional (entrega,
/// parecer de revisão), ela abre o modal de detalhe da missão em vez de
/// mover silenciosamente.
class MissionKanbanBoard extends StatelessWidget {
  final List<Missao> missoes;
  final Future<void> Function() onChanged;

  const MissionKanbanBoard({super.key, required this.missoes, required this.onChanged});

  /// Coordenador, Revisor e Admin enxergam e movem o quadro inteiro (o único
  /// limite real é a trava de SoD do backend: revisor não aprova a própria
  /// entrega). Colaborador só mexe nas missões em que é responsável, e nunca
  /// decide Aprovada/Rejeitada — isso é sempre decisão de quem revisa.
  bool _gerenciaTudo(AuthProvider auth) => auth.isAdmin || auth.isLider || auth.isRevisor;

  bool _aceita(BuildContext context, Missao arrastada, MissaoStatus alvo) {
    if (arrastada.status == alvo) return false;
    final auth = context.read<AuthProvider>();
    final gerenciaTudo = _gerenciaTudo(auth);
    final ehResponsavel = arrastada.responsavelId != null && arrastada.responsavelId == auth.currentUser?.id;
    final podeMovimentar = gerenciaTudo || ehResponsavel;

    switch (alvo) {
      case MissaoStatus.pendente:
        return false; // nenhum papel "desfaz" pra pendente
      case MissaoStatus.emAndamento:
        // Iniciar (vindo de Pendente) ou "pegar de volta" uma rejeitada pra corrigir.
        return (arrastada.status == MissaoStatus.pendente || arrastada.status == MissaoStatus.rejeitada) && podeMovimentar;
      case MissaoStatus.emRevisao:
        return (arrastada.status == MissaoStatus.emAndamento || arrastada.status == MissaoStatus.rejeitada) && podeMovimentar;
      case MissaoStatus.aprovada:
      case MissaoStatus.rejeitada:
        return arrastada.status == MissaoStatus.emRevisao && gerenciaTudo;
    }
  }

  Future<void> _tratarSolta(BuildContext context, Missao missao, MissaoStatus alvo) async {
    final provider = context.read<WorkspaceProvider>();
    if (alvo == MissaoStatus.emAndamento) {
      // Única transição que não precisa de informação extra: dispara direto
      // (serve tanto para "iniciar" quanto para "retomar após rejeição").
      await provider.iniciarMissao(missao.id);
      await onChanged();
    } else {
      // As demais (entrega, aprovação/rejeição) exigem texto/parecer — abre o
      // modal de detalhe, que já tem os botões certos disponíveis.
      await showMissionDetailDialog(context, missao, onChanged: onChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile(context)) {
      // Em telas estreitas, 5 colunas flexíveis ficam ilegíveis — em vez
      // disso cada coluna ganha largura fixa e o quadro rola horizontalmente.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: MissaoStatus.values
              .map((status) => [
                    SizedBox(width: 260, child: _buildColuna(context, status)),
                    const SizedBox(width: 12),
                  ])
              .expand((w) => w)
              .toList()
            ..removeLast(),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: MissaoStatus.values
          .map((status) => [
                Expanded(child: _buildColuna(context, status)),
                const SizedBox(width: 12),
              ])
          .expand((w) => w)
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildColuna(BuildContext context, MissaoStatus status) {
    final missoesDaColuna = missoes.where((m) => m.status == status).toList();

    return DragTarget<Missao>(
      onWillAcceptWithDetails: (details) => _aceita(context, details.data, status),
      onAcceptWithDetails: (details) => _tratarSolta(context, details.data, status),
      builder: (context, candidateData, rejectedData) {
        final destacado = candidateData.isNotEmpty;
        final recusado = rejectedData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: recusado ? AppTheme.statusRejected : (destacado ? AppTheme.primary : AppTheme.border), width: destacado || recusado ? 2 : 1),
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(missaoStatusLabel(status), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(12)),
                      child: Text('${missoesDaColuna.length}', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: missoesDaColuna.map((m) {
                    final auth = context.read<AuthProvider>();
                    final ehResponsavel = m.responsavelId != null && m.responsavelId == auth.currentUser?.id;
                    final somenteLeitura = !_gerenciaTudo(auth) && !ehResponsavel;
                    return MissionCard(
                      missao: m,
                      somenteLeitura: somenteLeitura,
                      onTap: () => showMissionDetailDialog(context, m, onChanged: onChanged),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
