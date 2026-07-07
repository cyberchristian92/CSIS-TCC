import 'package:flutter/material.dart';
import '../widgets/project_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plataforma CSIS - Dashboard'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Visão Geral'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Projetos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: Text('Missões'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_rtl_outlined),
                selectedIcon: Icon(Icons.checklist_rtl),
                label: Text('Entregas'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedIndex != 1) {
      return Center(
        child: Text('Conteúdo em construção...',
            style: Theme.of(context).textTheme.headlineSmall),
      );
    }

    // Conteúdo da aba Projetos (Mock)
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meus Projetos', style: Theme.of(context).textTheme.headlineMedium),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Novo Projeto'),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                ProjectCard(
                  title: 'Perícia Digital Caso X',
                  area: 'Perícia',
                  status: 'ATIVO',
                  progress: 0.6,
                ),
                ProjectCard(
                  title: 'Campanha de Marketing Q3',
                  area: 'Marketing',
                  status: 'ATIVO',
                  progress: 0.3,
                ),
                ProjectCard(
                  title: 'Módulo de Segurança Web',
                  area: 'Cursos',
                  status: 'CONCLUÍDO',
                  progress: 1.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
