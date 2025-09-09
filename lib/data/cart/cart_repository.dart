import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cart.dart';
import '../../models/cartItems.dart';

class CartRepository extends ChangeNotifier {
  final SupabaseClient _client;
  List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  CartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<String> getOrCreateCart(String userId) async {
    // 1. Busca carrinhos existentes ativos do usuário
    final cartsResponse = await _client
        .from('carts')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    if (cartsResponse is List && cartsResponse.isNotEmpty) {
      final cart = cartsResponse.first;
      if (cart != null && cart['id'] != null) {
        return cart['id'] as String;
      }
    }

    // 2. Se não houver carrinho ativo, cria um novo
    final insertResponse =
        await _client
            .from('carts')
            .insert({'user_id': userId, 'status': 'active'})
            .select()
            .single();

    if (insertResponse != null && insertResponse['id'] != null) {
      return insertResponse['id'] as String;
    }

    // 3. Caso algo dê errado
    throw Exception(
      'Não foi possível obter ou criar um carrinho para o usuário $userId',
    );
  }

  Future<List<CartItem>> fetchCartItems(String userId) async {
    final response = await _client
        .from('cart_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response is List) {
      final items = response.map((e) => CartItem.fromJson(e)).toList();
      _items = items;
      notifyListeners();
      return items;
    }

    return [];
  }

  //notifyListeners();

  Future<void> addItem(CartItem item) async {
    try {
      final itemToInsert = item.toJson()..remove('id');

      final response =
          await _client
              .from('cart_items')
              .insert(itemToInsert)
              .select()
              .single(); // retorna apenas o item inserido

      final newItem = CartItem.fromJson(response);
      _items.insert(0, newItem);
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar item: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      // Remove do banco
      await _client.from('cart_items').delete().eq('id', itemId);

      // Remove da lista local
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      print('Erro ao remover item: $e');
      throw Exception('Failed to remove item from cart');
    }
  }
}
