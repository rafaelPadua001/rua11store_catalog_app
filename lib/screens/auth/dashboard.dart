import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rua11store_catalog_app/data/user_profile/user_profile_repository.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user/profile_user.dart';


class Dashboard extends StatefulWidget {
  @override
  _StateDashboard createState() => _StateDashboard();
}

class _StateDashboard extends State<Dashboard> {
  int _selectedIndex = 0;
  UserModel? user;
  bool isLoading = true;
  final UserProfileRepository _userProfileRepository = UserProfileRepository();

  final List<Widget> _widgetOptions = [
    Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(children: [Text('Página Inicial')]),
      ),
    ),
    Center(child: Text('Página de Produtos')),
    // Center(child: Text('Página de Configurações')),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userProfileRepository.getProfile();
      setState(() {
        user = userData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do usuário: ${e.toString()}')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2 && user != null) {
      _navigateToProfile();
    }
    if (index == 4) {
      _handleLogout(context);
    }
  }

  Future<void> _navigateToProfile() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileUserWidget(
            user: user!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao navegar: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout realizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
              NavigationRailDestination(
                icon: Icon(Icons.logout_outlined),
                selectedIcon: Icon(Icons.logout),
                label: Text('Logout'),
              ),
            ],
          ),
          VerticalDivider(thickness: 0, width: 0.1),
          Expanded(child: _widgetOptions.elementAt(_selectedIndex < _widgetOptions.length ? _selectedIndex : 0)),
        ],
      ),
    );
  }
}