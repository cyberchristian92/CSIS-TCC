import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class AreasListScreen extends StatelessWidget {
  const AreasListScreen({super.key});

  void _showNewAreaModal(BuildContext context) {
    final nameController = TextEditingController();
    final managerController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Nova Área'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome da Área'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: managerController,
                decoration: const InputDecoration(labelText: 'Gerente / Responsável'),
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
                if (nameController.text.isNotEmpty) {
                  final newArea = Area(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    manager: managerController.text.isEmpty ? 'Não definido' : managerController.text,
                    activeProjects: 0,
                  );
                  Provider.of<AppState>(context, listen: false).addArea(newArea);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final areas = appState.areas;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestão de Áreas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewAreaModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Área'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                children: [
                  _buildTableHeader(),
                  ...areas.map((a) {
                    return Column(
                      children: [
                        _buildTableRow(a),
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
          Expanded(flex: 2, child: Text('NOME DA ÁREA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('GESTOR', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('PROJETOS ATIVOS', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('AÇÕES', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Area area) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(area.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          Expanded(flex: 2, child: Text(area.manager, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Expanded(flex: 1, child: Text('${area.activeProjects}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 18, color: AppTheme.textSecondary), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
