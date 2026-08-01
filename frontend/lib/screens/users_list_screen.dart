import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';

const _papeis = ['ADMIN', 'LIDER', 'REVISOR', 'COLABORADOR'];

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    await context.read<WorkspaceProvider>().carregarUsuarios();
    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _showNewUserModal(WorkspaceProvider provider, bool souAdmin) async {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    String papel = 'COLABORADOR';
    bool enviando = false;
    String? erro;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Convidar Usuário'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome Completo')),
                const SizedBox(height: 16),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail Institucional'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                TextField(controller: senhaController, decoration: const InputDecoration(labelText: 'Senha temporária (mín. 8 caracteres)'), obscureText: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Papel Global'),
                  initialValue: papel,
                  items: _papeis
                      .where((p) => p != 'ADMIN' || souAdmin) // só Admin pode criar outro Admin
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setState(() => papel = val ?? papel),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 12),
                  Text(erro!, style: const TextStyle(color: AppTheme.statusRejected, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: enviando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (nomeController.text.trim().isEmpty || emailController.text.trim().isEmpty || senhaController.text.length < 8) {
                          setState(() => erro = 'Preencha nome, e-mail e uma senha com pelo menos 8 caracteres.');
                          return;
                        }
                        setState(() => enviando = true);
                        try {
                          await provider.criarUsuario(nomeController.text.trim(), emailController.text.trim(), senhaController.text, papel);
                          if (context.mounted) Navigator.pop(ctx);
                          await _carregar();
                        } catch (e) {
                          setState(() {
                            enviando = false;
                            erro = e.toString();
                          });
                        }
                      },
                child: enviando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                    : const Text('Enviar Convite'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _alterarPapel(WorkspaceProvider provider, User usuario, String novoPapel) async {
    try {
      await provider.atualizarPapelUsuario(usuario.id, novoPapel);
      await _carregar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final auth = context.watch<AuthProvider>();
    final usuarios = provider.usuarios;

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
                  Text('Usuários e Perfis', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Gestão de acesso e privilégios da plataforma.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewUserModal(provider, auth.isAdmin),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Convidar Usuário'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(AppTheme.radius)),
              child: _carregando
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : usuarios.isEmpty
                      ? const Center(child: Text('Nenhum usuário ainda.', style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView(
                          children: [
                            _buildTableHeader(),
                            ...usuarios.map((u) => Column(
                                  children: [
                                    _buildTableRow(provider, auth, u),
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
          Expanded(flex: 3, child: Text('USUÁRIO', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('PAPEL', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text('DESDE', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTableRow(WorkspaceProvider provider, AuthProvider auth, User usuario) {
    final souEu = usuario.id == auth.currentUser?.id;
    final souAdmin = auth.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  radius: 16,
                  child: Text(usuario.iniciais, style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        if (souEu) ...[
                          const SizedBox(width: 6),
                          Text('(você)', style: TextStyle(fontSize: 11, color: AppTheme.textDisabled)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(usuario.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: souEu
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.border)),
                    child: Text(usuario.papelGlobal, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  )
                : DropdownButton<String>(
                    value: usuario.papelGlobal,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                    dropdownColor: AppTheme.surfaceRaised,
                    items: _papeis
                        .where((p) => p != 'ADMIN' || souAdmin)
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null && val != usuario.papelGlobal) _alterarPapel(provider, usuario, val);
                    },
                  ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              usuario.criadoEm != null ? '${usuario.criadoEm!.day}/${usuario.criadoEm!.month}/${usuario.criadoEm!.year}' : '—',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
