import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/hierarchy_models.dart';
import 'package:frontend/providers/workspace_provider.dart';

const _tiposArea = ['PERICIA', 'MARKETING', 'CURSOS'];

class AreasListScreen extends StatefulWidget {
  const AreasListScreen({super.key});

  @override
  State<AreasListScreen> createState() => _AreasListScreenState();
}

class _AreasListScreenState extends State<AreasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WorkspaceProvider>().carregarAreas());
  }

  Future<void> _showAreaModal(WorkspaceProvider provider, {AreaApi? area}) async {
    final nomeController = TextEditingController(text: area?.nome ?? '');
    String tipo = area?.tipo ?? _tiposArea.first;
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(area == null ? 'Nova Área' : 'Editar Área'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome da Área')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  initialValue: tipo,
                  items: _tiposArea.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => tipo = val ?? tipo),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (nomeController.text.trim().isEmpty) return;
                        setState(() => enviando = true);
                        if (area == null) {
                          await provider.criarArea(nomeController.text.trim(), tipo);
                        } else {
                          await provider.atualizarArea(area.id, nome: nomeController.text.trim(), tipo: tipo);
                        }
                        if (context.mounted) Navigator.pop(ctx);
                      },
                child: enviando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                    : const Text('Salvar'),
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
    final areas = provider.areas;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestão de Áreas', style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: () => _showAreaModal(provider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova Área'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: areas.isEmpty
                  ? const Center(child: Text('Nenhuma área ainda.', style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView(
                      children: [
                        _buildTableHeader(),
                        ...areas.map((a) => Column(
                              children: [
                                _buildTableRow(provider, a),
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
          Expanded(flex: 3, child: Text('NOME DA ÁREA', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('TIPO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          SizedBox(width: 96, child: Text('AÇÕES', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(WorkspaceProvider provider, AreaApi area) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(area.nome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          Expanded(flex: 2, child: Text(area.tipo, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          SizedBox(
            width: 96,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 18, color: AppTheme.textSecondary), onPressed: () => _showAreaModal(provider, area: area)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.statusRejected), onPressed: () => provider.removerArea(area.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
