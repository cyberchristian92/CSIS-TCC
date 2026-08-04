import 'package:flutter/widgets.dart';

/// Limiar único de "celular vs desktop" reaproveitado em todo o app —
/// evita cada tela inventar seu próprio breakpoint.
bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 800;
