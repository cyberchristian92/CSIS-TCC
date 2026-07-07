import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/projects_list_screen.dart';
import 'package:frontend/screens/my_missions_screen.dart';
import 'package:frontend/screens/review_queue_screen.dart';
import 'package:frontend/screens/areas_list_screen.dart';
import 'package:frontend/screens/project_types_screen.dart';
import 'package:frontend/screens/users_list_screen.dart';
import 'package:frontend/screens/audit_log_screen.dart';
import 'package:frontend/screens/archive_screen.dart';

class ScaffoldScreen extends StatefulWidget {
  const ScaffoldScreen({super.key});

  @override
  State<ScaffoldScreen> createState() => _ScaffoldScreenState();
}

class _ScaffoldScreenState extends State<ScaffoldScreen> {
  int _selectedIndex = 0;

  // Placeholder para as telas reais depois
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProjectsListScreen(),
    const MyMissionsScreen(),
    const ReviewQueueScreen(),
    const AreasListScreen(),
    const ProjectTypesScreen(),
    const UsersListScreen(),
    const AuditLogScreen(),
    const ArchiveScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header da Sidebar (Logo)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/logo.svg',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CSIS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Itens de Menu (Admin view)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(0, 'Painel', Icons.dashboard_outlined),
                      
                      _buildExpansionGroup(
                        'Projetos',
                        Icons.folder_outlined,
                        [
                          _buildExpansionItem(1, 'Projetos Abertos'),
                          _buildExpansionItem(2, 'Minhas Missões'),
                          _buildExpansionItem(3, 'Fila de Revisão'),
                        ],
                      ),

                      _buildExpansionGroup(
                        'Áreas',
                        Icons.domain_outlined,
                        [
                          _buildExpansionItem(4, 'Gestão de Áreas'),
                          _buildExpansionItem(5, 'Tipos de Projeto'),
                        ],
                      ),

                      _buildExpansionGroup(
                        'Recursos',
                        Icons.settings_suggest_outlined,
                        [
                          _buildExpansionItem(6, 'Gestão de Usuários'),
                          _buildExpansionItem(7, 'Auditoria Global'),
                        ],
                      ),

                      _buildExpansionGroup(
                        'Arquivamento',
                        Icons.archive_outlined,
                        [
                          _buildExpansionItem(8, 'Projetos Arquivados'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // User Menu
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Text('A', style: TextStyle(color: AppTheme.primary)),
                  ),
                  title: const Text('Admin', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Sair', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 64,
                  color: AppTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Search bar
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
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
                      // Notifications
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                            onPressed: () {},
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.statusRejected,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
                // Tela selecionada
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(left: BorderSide(color: AppTheme.primary, width: 3))
              : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionGroup(String title, IconData icon, List<Widget> children) {
    return ExpansionTile(
      leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      iconColor: AppTheme.textSecondary,
      collapsedIconColor: AppTheme.textSecondary,
      childrenPadding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _buildExpansionItem(int index, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 60, top: 10, bottom: 10, right: 24),
        color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
