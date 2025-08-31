import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/screens/auth/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/auth/login.dart';
import 'cart_menu.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarExample extends StatefulWidget implements PreferredSizeWidget {
  const AppBarExample({super.key});

  @override
  State<AppBarExample> createState() => _AppBarExampleState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarExampleState extends State<AppBarExample> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;

    // Escuta mudanças de autenticação (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      setState(() {
        _user = Supabase.instance.client.auth.currentUser;
      });
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
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
    return AppBar(
      title: Text(
        'Rua11Store',
        style: GoogleFonts.lobster(
          textStyle: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: <Widget>[
        CartMenu(),
        MenuAnchor(
          alignmentOffset: const Offset(
            0,
            8,
          ), // desloca o menu 8 pixels para baixo
          builder: (
            BuildContext context,
            MenuController controller,
            Widget? child,
          ) {
            return IconButton(
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              onPressed: () {
                controller.isOpen ? controller.close() : controller.open();
              },
            );
          },
          menuChildren: [
            if (_user == null)
              MenuItemButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 5),
                    Text('Login'),
                  ],
                ),
              ),
            if (_user != null) ...[
              MenuItemButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Dashboard()),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.dashboard),
                    SizedBox(width: 5),
                    Text('Dashboard'),
                  ],
                ),
              ),
              MenuItemButton(
                onPressed: () => _handleLogout(context),
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 5),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
