import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/scaffold_screen.dart';
import 'package:frontend/screens/reset_password_screen.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => WorkspaceProvider()),
      ],
      child: const CsisApp(),
    ),
  );
}

class CsisApp extends StatelessWidget {
  const CsisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Link de redefinição de senha vindo por email: http://.../?token=...
    // Checado aqui, antes do AuthGate, pra não depender de sessão logada.
    final tokenRecuperacao = Uri.base.queryParameters['token'];

    return MaterialApp(
      title: 'Plataforma CSIS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: tokenRecuperacao != null && tokenRecuperacao.isNotEmpty
          ? ResetPasswordScreen(token: tokenRecuperacao)
          : const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const ScaffoldScreen(),
      },
    );
  }
}

/// Ao abrir o app, checa se o cookie HttpOnly de sessão ainda é válido
/// (`GET /auth/me`) antes de decidir entre tela de login ou dashboard —
/// evita jogar o usuário pro login só porque a página foi recarregada.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tentarRestaurarSessao();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return auth.isAutenticado ? const ScaffoldScreen() : const LoginScreen();
  }
}
