import 'package:flutter/material.dart';
import 'package:rua11store_catalog_app/catalog_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rua11store_catalog_app/data/user_profile/user_profile_repository.dart';
import 'package:rua11store_catalog_app/main.dart';
import 'package:rua11store_catalog_app/models/user.dart';
import '../user/profile_user.dart';
import '../orders/orders_widget.dart';
import '../cart/cart_widget.dart';
import '../coupon/couponpage.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _StateDashboard createState() => _StateDashboard();
}

class _StateDashboard extends State<Dashboard> {
  int _selectedIndex = 0;
  UserModel? user;
  bool isLoading = true;
  final UserProfileRepository _userProfileRepository = UserProfileRepository();

  int cartItemsCount = 0;
  int orderCount = 0;
  int couponCount = 0;

  List<dynamic> _orders = [];

  final apiUrl = dotenv.env['API_URL'];

  List<Widget> get _widgetOptions {
    return [
      Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  Chip(
                    label: Text('Carrinho: ($cartItemsCount)'),
                    avatar: Icon(Icons.shopping_cart, color: Colors.white),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  Chip(
                    label: Text('Pedidos: ($orderCount)'),
                    avatar: Icon(Icons.receipt, color: Colors.white),
                    backgroundColor: Colors.lightGreen,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  Chip(
                    label: Text('Cupons: ($couponCount)'),
                    avatar: Icon(Icons.card_giftcard, color: Colors.white),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildOrdersCategoryCard(context)),
                  SizedBox(width: 12), // Espaço entre os cards
                  Expanded(child: _buildRecentOrders(context)),
                ],
              ),
              Row(
                children: [
                  // Espaço entre os cards
                  Expanded(child: _buildOrdersCard(context)),
                  SizedBox(width: 12), // Espaço entre os cards
                  Expanded(child: _buildCouponsCard(context)),
                  SizedBox(width: 12), // Espaço entre os cards
                  Expanded(child: _buildCartsCard(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

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
      });

      await _loadDashboardCounts();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados do usuário: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _loadOrdersFromApi() async {
    final userId = user?.id;
    if (userId == null) return;

    try {
      final baseUrl =
          apiUrl!.endsWith('/')
              ? apiUrl!.substring(0, apiUrl!.length - 1)
              : apiUrl!;
      final response = await http.get(
        Uri.parse('$baseUrl/order/get-order/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> ordersList = data;

        setState(() {
          _orders = data;
          orderCount = ordersList.length;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      debugPrint('Erro ao carregar pedidos: $e');
      setState(() {
        orderCount = 0;
        _orders = [];
      });
    }
    return;
  }

  Future<void> _loadCouponsFromApi() async {
    final userId = user?.id;
    if (userId == null) return;

    try {
      final baseUrl =
          apiUrl!.endsWith('/')
              ? apiUrl!.substring(0, apiUrl!.length - 1)
              : apiUrl!;

      final response = await http.get(
        Uri.parse('$baseUrl/coupon/get-coupons/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> couponsList = data;

        setState(() {
          couponCount = couponsList.length;
        });
      } else {
        throw Exception('Failed to load couponCountrs');
      }
    } catch (e) {
      debugPrint('Erro ao carregar cupons: $e');
      setState(() {
        couponCount = 0;
      });
    }
    return;
  }

  Future<void> _loadDashboardCounts() async {
    final supabase = Supabase.instance.client;

    try {
      //load cart countItems
      final response = await Supabase.instance.client
          .from('cart')
          .select()
          .eq('user_id', user!.id);

      setState(() {
        cartItemsCount = response.length;
      });
    } catch (e) {
      debugPrint('Erro ao buscar contagens: $e');
      setState(() {
        cartItemsCount = 0;
      });
    }

    await _loadOrdersFromApi();
    await _loadCouponsFromApi();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _navigateToCoupons();
    }
    if (index == 2 && user != null) {
      _navigateToCart();
    }
    if (index == 3 && user != null) {
      _navigateToOrders();
    }
    if (index == 4 && user != null) {
      _navigateToProfile();
    }
    if (index == 5) {
      _handleLogout(context);
    }
  }

  String formatOrderDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year} às ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    } catch (e) {
      return 'Data inválida';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  Future<void> _navigateToProfile() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileUserWidget(user: user!)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao navegar: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToOrders() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OrdersWidget(
                //user: user!,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao navegar: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToCart() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartWidget(userId: user!.id)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao navegar: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToCoupons() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CouponPage(userId: user!.id)),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.notifications),
            onSelected: (value) {
              // Mapear os valores para índices que o NavigationRail usa
              final menuIndexMap = {
                'inicio': 0,
                'perfil': 4,
                'configuracoes': 7,
                'logout': 5,
              };

              int? index = menuIndexMap[value];
              if (index != null) {
                _onItemTapped(index);
              }
            },
            itemBuilder:
                (context) => [
                  //PopupMenuItem(value: 'inicio', child: Text('Início')),
                  PopupMenuItem(value: 'perfil', child: Text('Perfil')),
                  PopupMenuItem(
                    value: 'configuracoes',
                    child: Text('Configurações'),
                  ),
                  PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(
                16.0,
              ), // se quiser manter espaçamento
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200),
                child: _widgetOptions.elementAt(
                  _selectedIndex < _widgetOptions.length ? _selectedIndex : 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildOrdersCategoryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Pedidos Por Categoria:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildRecentOrders(BuildContext context) {
    final recentOrders = _orders.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Atividades Recentes:',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            ...recentOrders.map(
              (order) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
                title: Text(
                  'Pedido #${order['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data: ${formatOrderDate(order['order_date']) ?? 'sem data'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      'Status: ${order['status'] ?? 'desconhecido'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                trailing: Text(
                  'R\$ ${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildOrdersCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _onItemTapped(3),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
                  const SizedBox(
                    width: 4,
                  ), // espaço horizontal entre ícone e texto
                  const Text(
                    'Pedidos',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildCouponsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _onItemTapped(1),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.orange, size: 20),
                  const SizedBox(
                    width: 4,
                  ), // espaço horizontal entre ícone e texto
                  const Text(
                    'Cupons',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget _buildCartsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, color: Colors.green, size: 20),
                  const SizedBox(
                    width: 4,
                  ), // espaço horizontal entre ícone e texto
                  const Text(
                    'Carrinho',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
