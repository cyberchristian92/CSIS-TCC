import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/main.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/workspace_provider.dart';

void main() {
  testWidgets('App mostra a tela de login quando não autenticado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AppState()),
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider(create: (context) => WorkspaceProvider()),
        ],
        child: const CsisApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Entrar'), findsWidgets);
  });
}
