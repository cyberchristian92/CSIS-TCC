import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasError = false;

  void _login() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }
    
    // Simulação simples: qualquer preenchimento não vazio passa.
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Lado do formulário
          Container(
            width: isDesktop ? 480 : size.width,
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
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
                      // Remova a cor caso a logo já tenha as cores corretas
                      // colorFilter: const ColorFilter.mode(AppTheme.primary, BlendMode.srcIn),
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
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'E-mail corporativo',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Senha',
                  ),
                  obscureText: true,
                ),
                if (_hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    'E-mail ou senha incorretos.',
                    style: TextStyle(color: AppTheme.statusRejected, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Simula esqueci a senha
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                    child: const Text('Esqueci minha senha'),
                  ),
                ),
              ],
            ),
          ),
          // Área restante no desktop com fundo liso cinza
          if (isDesktop)
            Expanded(
              child: Container(
                color: AppTheme.background,
              ),
            ),
        ],
      ),
    );
  }
}
