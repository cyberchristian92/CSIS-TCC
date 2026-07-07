import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class ResourcesListScreen extends StatelessWidget {
  const ResourcesListScreen({super.key});

  void _showNewResourceModal(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Novo Recurso (Usuário)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Cargo / Perfil (Ex: Analista)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-mail Institucional'),
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
                  final newUser = UserResource(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    role: roleController.text.isEmpty ? 'Usuário' : roleController.text,
                    email: emailController.text.isEmpty ? 'sem@email.com' : emailController.text,
                  );
                  Provider.of<AppState>(context, listen: false).addResource(newUser);
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
    final resources = appState.resources;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestão de Recursos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewResourceModal(context),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Novo Recurso'),
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
                  ...resources.map((r) {
                    return Column(
                      children: [
                        _buildTableRow(r),
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
          Expanded(flex: 3, child: Text('NOME', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('CARGO/PERFIL', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text('E-MAIL', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(UserResource resource) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(resource.name[0], style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(resource.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            )
          ),
          Expanded(flex: 2, child: Text(resource.role, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Expanded(flex: 3, child: Text(resource.email, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          const Expanded(
            flex: 1,
            child: Text('Ativo', style: TextStyle(color: AppTheme.statusApproved, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
