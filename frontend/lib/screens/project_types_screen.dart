import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class ProjectTypesScreen extends StatelessWidget {
  const ProjectTypesScreen({super.key});

  void _showAddProjectTypeModal(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final fieldsCountController = TextEditingController();
    String? selectedArea;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Novo Tipo de Projeto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome do Tipo (ex: Auditoria Interna)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Área Padrão'),
                  value: selectedArea,
                  items: appState.areas.map((a) {
                    return DropdownMenuItem(value: a.name, child: Text(a.name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedArea = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fieldsCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade de Campos Customizados (Mock)'),
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
                  if (nameController.text.isNotEmpty && selectedArea != null) {
                    final type = ProjectType(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      area: selectedArea!,
                      customFieldsCount: int.tryParse(fieldsCountController.text) ?? 0,
                    );
                    appState.addProjectType(type);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                  Text('Tipos de Projeto', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Moldes pré-definidos para criação de projetos.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProjectTypeModal(context, appState),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Tipo'),
              ),
            ],
          ),
          const SizedBox(height: 32),
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
                  ...appState.projectTypes.map((type) {
                    return Column(
                      children: [
                        _buildTableRow(type),
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
          Expanded(flex: 2, child: Text('NOME DO TIPO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('ÁREA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('CAMPOS CUSTOM.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(ProjectType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.domain, size: 16, color: AppTheme.textDisabled),
                const SizedBox(width: 8),
                Text(type.area, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                '${type.customFieldsCount} campos',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
