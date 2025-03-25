import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  @override
  _StateDashboard createState() => _StateDashboard();
}

class _StateDashboard extends State<Dashboard> {
  int _selectedIndex = 0; // Índice do item selecionado no NavigationRail

  // Conteúdo exibido de acordo com o item selecionado
  final List<Widget> _widgetOptions = [
    Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Página Inicial'),
          ],
        ),
      ),
    ),
    Center(child: Text('Página de Produtos')),
    Center(child: Text('Página de Perfil')),
    Center(child: Text('Página de Configurações')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Início'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: Text('Produtos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Configurações'),
              ),
            ],
          ),
           VerticalDivider(thickness: 0, width: 0.1),
          // Conteúdo principal
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}