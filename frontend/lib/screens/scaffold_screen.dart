import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/theme/responsive.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/projects_list_screen.dart';
import 'package:frontend/screens/my_missions_screen.dart';
import 'package:frontend/screens/review_queue_screen.dart';
import 'package:frontend/screens/areas_list_screen.dart';
import 'package:frontend/screens/project_types_screen.dart';
import 'package:frontend/screens/users_list_screen.dart';
import 'package:frontend/screens/audit_log_screen.dart';
import 'package:frontend/screens/archive_screen.dart';

enum _Secao { dashboard, projetos, minhasMissoes, revisao, areas, tiposProjeto, usuarios, auditoria, arquivamento }

class ScaffoldScreen extends StatefulWidget {
  const ScaffoldScreen({super.key});

  @override
  State<ScaffoldScreen> createState() => _ScaffoldScreenState();
}

class _ScaffoldScreenState extends State<ScaffoldScreen> {
  _Secao _secao = _Secao.dashboard;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildBody() {
    switch (_secao) {
      case _Secao.dashboard:
        return DashboardScreen(onNavigateToAudit: () => setState(() => _secao = _Secao.auditoria));
      case _Secao.projetos:
        return const ProjectsListScreen();
      case _Secao.minhasMissoes:
        return const MyMissionsScreen();
      case _Secao.revisao:
        return const ReviewQueueScreen();
      case _Secao.areas:
        return const AreasListScreen();
      case _Secao.tiposProjeto:
        return const ProjectTypesScreen();
      case _Secao.usuarios:
        return const UsersListScreen();
      case _Secao.auditoria:
        return const AuditLogScreen();
      case _Secao.arquivamento:
        return const ArchiveScreen();
    }
  }

  Widget _buildSidebarContent(AuthProvider auth, bool ehGestor, bool podeRevisar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              SvgPicture.asset('assets/logo.svg', width: 32, height: 32),
              const SizedBox(width: 12),
              Text(
                'CSIS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildNavItem(_Secao.dashboard, 'Painel', Icons.dashboard_outlined),
              _buildExpansionGroup('Projetos', Icons.folder_outlined, [
                _buildExpansionItem(_Secao.projetos, 'Projetos Abertos'),
                _buildExpansionItem(_Secao.minhasMissoes, 'Minhas Missões'),
                if (podeRevisar) _buildExpansionItem(_Secao.revisao, 'Fila de Revisão'),
              ]),
              if (ehGestor)
                _buildExpansionGroup('Áreas', Icons.domain_outlined, [
                  _buildExpansionItem(_Secao.areas, 'Gestão de Áreas'),
                  _buildExpansionItem(_Secao.tiposProjeto, 'Tipos de Projeto'),
                ]),
              if (ehGestor)
                _buildExpansionGroup('Recursos', Icons.settings_suggest_outlined, [
                  _buildExpansionItem(_Secao.usuarios, 'Gestão de Usuários'),
                  _buildExpansionItem(_Secao.auditoria, 'Auditoria Global'),
                ]),
              _buildExpansionGroup('Arquivamento', Icons.archive_outlined, [
                _buildExpansionItem(_Secao.arquivamento, 'Projetos Arquivados'),
              ]),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: Text(auth.currentUser?.iniciais ?? '?', style: const TextStyle(color: AppTheme.primary)),
          ),
          title: Text(auth.currentUser?.nome ?? '', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
          subtitle: Text(auth.currentUser?.papelGlobal ?? '', style: const TextStyle(fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppTheme.textSecondary),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ehGestor = auth.isAdmin || auth.isLider;
    final podeRevisar = auth.isAdmin || auth.isLider || auth.isRevisor;
    final mobile = isMobile(context);
    final sidebar = _buildSidebarContent(auth, ehGestor, podeRevisar);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: mobile
          ? Drawer(
              backgroundColor: AppTheme.surface,
              child: SafeArea(child: sidebar),
            )
          : null,
      body: Row(
        children: [
          if (!mobile) ...[
            Container(width: 220, color: AppTheme.surface, child: sidebar),
            const VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
          ],
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      if (mobile) ...[
                        IconButton(
                          icon: const Icon(Icons.menu, color: AppTheme.textSecondary),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search, color: AppTheme.textDisabled),
                          onPressed: () {},
                        ),
                        const Spacer(),
                      ] else
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppTheme.textDisabled, size: 20),
                                SizedBox(width: 8),
                                Text('Buscar...', style: TextStyle(color: AppTheme.textDisabled)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selecionar(_Secao secao) {
    setState(() => _secao = secao);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Widget _buildNavItem(_Secao secao, String title, IconData icon) {
    final isSelected = _secao == secao;
    return InkWell(
      onTap: () => _selecionar(secao),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: isSelected ? const Border(left: BorderSide(color: AppTheme.primary, width: 3)) : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionGroup(String title, IconData icon, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
      iconColor: AppTheme.textSecondary,
      collapsedIconColor: AppTheme.textSecondary,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: true,
      children: children,
    );
  }

  Widget _buildExpansionItem(_Secao secao, String title) {
    final isSelected = _secao == secao;
    return InkWell(
      onTap: () => _selecionar(secao),
      child: Container(
        padding: const EdgeInsets.only(left: 60, top: 10, bottom: 10, right: 24),
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        child: Text(title, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
      ),
    );
  }
}
