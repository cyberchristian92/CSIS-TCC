import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/forgot_password_screen.dart';
import 'package:frontend/services/api_client.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _enviando = false;
  bool _sucesso = false;
  String? _erro;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().redefinirSenha(widget.token, _senhaController.text);
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _sucesso = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = 'Erro inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Redefinir senha', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (_sucesso) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.statusApproved.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.statusApproved),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: const Text('Senha redefinida com sucesso. Você já pode entrar com a senha nova.', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    ),
                    child: const Text('Ir para o login'),
                  ),
                ] else if (_erro != null && _erro!.toLowerCase().contains('inválido')) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRejected.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.statusRejected),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Text(_erro!, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'O link pode ter expirado (validade de 1 hora) ou já ter sido usado.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Solicitar um novo link'),
                  ),
                ] else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _senhaController,
                          decoration: const InputDecoration(hintText: 'Nova senha (mín. 8 caracteres)'),
                          obscureText: true,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (value) {
                            if (value == null || value.length < 8) return 'A senha precisa ter pelo menos 8 caracteres.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmarController,
                          decoration: const InputDecoration(hintText: 'Confirmar nova senha'),
                          obscureText: true,
                          onFieldSubmitted: (_) => _redefinir(),
                          validator: (value) {
                            if (value != _senhaController.text) return 'As senhas não coincidem.';
                            return null;
                          },
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 12),
                          Text(_erro!, style: const TextStyle(color: AppTheme.statusRejected, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _enviando ? null : _redefinir,
                          child: _enviando
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                              : const Text('Redefinir senha'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
