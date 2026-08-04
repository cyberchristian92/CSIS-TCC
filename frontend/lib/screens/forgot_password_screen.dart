import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await context.read<AuthProvider>().esqueciSenha(_emailController.text.trim());
    } catch (_) {
      // Mesmo em erro de rede, mostramos a mesma confirmação — o backend já
      // responde 200 exista ou não a conta, então não há o que "vazar" aqui.
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _enviado = true;
    });
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                Text('Esqueci minha senha', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Informe o e-mail da sua conta. Se ele existir, você vai receber um link para redefinir a senha.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                if (_enviado)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.statusApproved.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.statusApproved),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: const Text(
                      'Se esse e-mail existir na plataforma, um link de redefinição foi enviado. Confira sua caixa de entrada.',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(hintText: 'E-mail corporativo'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _enviar(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Informe o e-mail.';
                            if (!value.contains('@') || !value.contains('.')) return 'E-mail inválido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _enviando ? null : _enviar,
                          child: _enviando
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                              : const Text('Enviar link'),
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
