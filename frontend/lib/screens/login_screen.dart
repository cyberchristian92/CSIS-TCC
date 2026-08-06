import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';
import 'package:frontend/services/fake_api_client.dart';
import 'package:frontend/services/fake_backend.dart';
import 'package:frontend/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _enviando = false;
  bool _entrandoDemo = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    final auth = context.read<AuthProvider>();
    final sucesso = await auth.login(_emailController.text.trim(), _passwordController.text);
    setState(() => _enviando = false);

    if (sucesso && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  /// Não há backend público hospedado ainda — este botão troca o cliente
  /// HTTP dos providers pelo [FakeApiClient] (dados fictícios, só em
  /// memória) e loga com a conta ADMIN de demonstração, pra dar pra navegar
  /// o app inteiro sem depender de nenhuma API real.
  Future<void> _entrarDemo() async {
    setState(() => _entrandoDemo = true);
    final auth = context.read<AuthProvider>();
    final workspace = context.read<WorkspaceProvider>();
    final cliente = FakeApiClient();
    auth.habilitarModoDemo(cliente);
    workspace.habilitarModoDemo(cliente);
    final sucesso = await auth.login(FakeBackend.emailDemo, FakeBackend.senhaDemo);
    if (!mounted) return;
    setState(() => _entrandoDemo = false);
    if (sucesso) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = !isMobile(context);
    final erro = context.watch<AuthProvider>().errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Lado do formulário
          Container(
            width: isDesktop ? 480 : size.width,
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo real em SVG
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/logo.svg',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CSIS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Entrar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesse a plataforma de gestão técnica',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'E-mail corporativo',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Informe o e-mail.';
                      if (!value.contains('@') || !value.contains('.')) return 'E-mail inválido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Senha',
                    ),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe a senha.';
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Esqueci minha senha', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      erro,
                      style: TextStyle(color: AppTheme.statusRejected, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _login,
                      child: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: const [Expanded(child: Divider(color: AppTheme.border)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('ou', style: TextStyle(color: AppTheme.textDisabled, fontSize: 12))), Expanded(child: Divider(color: AppTheme.border))]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _entrandoDemo ? null : _entrarDemo,
                      icon: _entrandoDemo
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                          : const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Entrar em modo demonstração'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Navega pelo app inteiro com dados de exemplo, sem precisar de um backend real. Nada do que você fizer aqui é salvo.',
                    style: TextStyle(color: AppTheme.textDisabled, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Área restante no desktop com o visual da marca
          if (isDesktop)
            Expanded(
              child: Container(
                color: AppTheme.background,
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.15,
                  child: SvgPicture.asset('assets/logo.svg', width: 320, height: 320),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
