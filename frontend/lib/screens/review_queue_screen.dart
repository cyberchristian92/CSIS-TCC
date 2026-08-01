import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/models/execution_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/services/api_client.dart';

class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _pendentes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    await provider.carregarProjetos();
    final pendentes = await provider.entregasPendentes();
    if (!mounted) return;
    setState(() {
      _pendentes = pendentes;
      _carregando = false;
    });
  }

  Future<void> _showReviewModal(BuildContext context, WorkspaceProvider provider, Missao missao, Entrega entrega) async {
    final commentController = TextEditingController();
    bool enviando = false;
    String? erro;

    Future<void> revisar(String status) async {
      enviando = true;
      erro = null;
      try {
        await provider.criarRevisao(entrega.id, status: status, comentario: commentController.text.trim());
        if (context.mounted) Navigator.pop(context);
        await _carregar();
      } on ApiException catch (e) {
        erro = e.message;
        enviando = false;
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Revisar Entrega: ${missao.titulo}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Autor: ${entrega.autorNome ?? 'Desconhecido'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4)),
                  child: Text(entrega.conteudo ?? '(sem descrição)', style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 24),
                const Text('Seu Parecer', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Escreva um comentário...', border: OutlineInputBorder()),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 12),
                  Text(erro!, style: const TextStyle(color: AppTheme.statusRejected, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusInReview, foregroundColor: Colors.black),
                onPressed: enviando ? null : () async { await revisar('REJEITADO'); setState(() {}); },
                child: const Text('Solicitar Ajustes'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusApproved),
                onPressed: enviando ? null : () async { await revisar('APROVADO'); setState(() {}); },
                child: const Text('Aprovar Entrega'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();

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
                  Text('Fila de Revisão', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Controle de Qualidade — entregas aguardando revisão', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar', onPressed: _carregar),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: _carregando
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _pendentes.isEmpty
                      ? const Center(child: Text('Nenhuma entrega aguardando revisão.', style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView(
                          children: [
                            _buildTableHeader(),
                            ..._pendentes.map((p) => Column(
                                  children: [
                                    _buildTableRow(context, provider, p),
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
          Expanded(flex: 3, child: Text('MISSÃO / PROJETO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('AUTOR', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('TEMPO NA FILA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('AÇÃO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, WorkspaceProvider provider, Map<String, dynamic> data) {
    final Projeto projeto = data['projeto'];
    final Missao missao = data['missao'];
    final Entrega entrega = data['entrega'];

    final diff = DateTime.now().difference(entrega.criadoEm);
    final timeStr = diff.inHours == 0 ? '${diff.inMinutes}m' : '${diff.inHours}h';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(missao.titulo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(projeto.nome, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    (entrega.autorNome?.isNotEmpty ?? false) ? entrega.autorNome![0] : '?',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(entrega.autorNome ?? 'Desconhecido', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(timeStr, style: const TextStyle(fontSize: 14, color: AppTheme.statusInReview, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () => _showReviewModal(context, provider, missao, entrega),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), minimumSize: const Size(0, 32)),
              child: const Text('Revisar', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
