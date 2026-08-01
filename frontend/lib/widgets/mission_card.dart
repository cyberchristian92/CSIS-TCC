import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';

/// Card de missão usado no Kanban (projeto e "Minhas Missões").
/// Arrastável (Trello-like) e clicável — o clique abre o modal de detalhe
/// com todas as ações (iniciar, entregar, revisar, atribuir, anexos).
class MissionCard extends StatelessWidget {
  final Missao missao;
  final VoidCallback onTap;
  final bool somenteLeitura;

  const MissionCard({super.key, required this.missao, required this.onTap, this.somenteLeitura = false});

  bool get _atrasada => missao.prazo != null && missao.prazo!.isBefore(DateTime.now()) && missao.status != MissaoStatus.aprovada;

  @override
  Widget build(BuildContext context) {
    return Draggable<Missao>(
      data: missao,
      maxSimultaneousDrags: somenteLeitura ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 240, child: _buildCard(elevado: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _buildCard()),
      child: InkWell(onTap: onTap, child: _buildCard()),
    );
  }

  Widget _buildCard({bool elevado = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: elevado ? 6 : 0,
      shape: RoundedRectangleBorder(side: const BorderSide(color: AppTheme.border), borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(missao.titulo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                if (somenteLeitura) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: 13, color: AppTheme.textDisabled)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        (missao.responsavelNome?.isNotEmpty ?? false) ? missao.responsavelNome![0] : '?',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(missao.responsavelNome?.split(' ').first ?? 'Sem responsável', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                if (missao.prazo != null)
                  Row(
                    children: [
                      if (_atrasada) const Padding(padding: EdgeInsets.only(right: 3), child: Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.statusRejected)),
                      Text(
                        '${missao.prazo!.day}/${missao.prazo!.month}',
                        style: TextStyle(color: _atrasada ? AppTheme.statusRejected : AppTheme.textDisabled, fontSize: 11, fontWeight: _atrasada ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
