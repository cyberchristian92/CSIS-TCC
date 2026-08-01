import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/widgets/mission_kanban_board.dart';

class MyMissionsScreen extends StatefulWidget {
  const MyMissionsScreen({super.key});

  @override
  State<MyMissionsScreen> createState() => _MyMissionsScreenState();
}

class _MyMissionsScreenState extends State<MyMissionsScreen> {
  bool _carregando = true;
  List<Missao> _missoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final provider = context.read<WorkspaceProvider>();
    final missoes = await provider.listarMinhasMissoes();
    if (!mounted) return;
    setState(() {
      _missoes = missoes;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Minhas Missões', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Tarefas atribuídas a você em todos os projetos — arraste os cards ou clique para ver detalhes', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar', onPressed: _carregar),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _missoes.isEmpty
                    ? const Center(child: Text('Nenhuma missão atribuída a você ainda.', style: TextStyle(color: AppTheme.textSecondary)))
                    : MissionKanbanBoard(missoes: _missoes, onChanged: _carregar),
          ),
        ],
      ),
    );
  }
}
