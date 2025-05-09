import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomNavigationRail extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  State<CustomNavigationRail> createState() => _CustomNavigationRailState();
}

class _CustomNavigationRailState extends State<CustomNavigationRail> {
  bool _isExtended = false;
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: _isExtended,
      minWidth: 56.0,
      leading: Column(
        children: [
          IconButton(
            icon: Icon(_isExtended ? Icons.chevron_left : Icons.chevron_right),
            onPressed: () {
              setState(() {
                _isExtended = !_isExtended;
              });
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: const Text('Início'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.shopping_bag_outlined),
          selectedIcon: const Icon(Icons.shopping_bag),
          label: const Text('Produtos'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outlined),
          selectedIcon: const Icon(Icons.person),
          label: const Text('Perfil'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: const Text('Configurações'),
        ),
      ],
      selectedIndex: widget.currentIndex,
      onDestinationSelected: widget.onDestinationSelected,
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () async {
                await _supabase.auth.signOut();
                // Navegar para tela de login após logout
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
