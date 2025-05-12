import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cart.dart';

class CartRepository extends ChangeNotifier {
  final SupabaseClient _client;
  List<CartItem> _items = [];

  List<CartItem> get items =>
      List.unmodifiable(_items); // Protege de modificações externas

  CartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<CartItem>> fetchCartItems(String userId) async {
    try {
      final response = await _client
          .from('cart')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final items =
          (response as List).map((item) => CartItem.fromJson(item)).toList();

      _items = items;
      notifyListeners();

      return items; // <-- esta linha é essencial
    } catch (e) {
      print('Erro ao buscar itens do carrinho: $e');
      rethrow;
    }
  }

  Future<void> addItem(CartItem item) async {
    try {
      final itemToInsert = item.toJson()..remove('id');
      print(itemToInsert);
      final response =
          await _client.from('cart').insert(itemToInsert).select().single();

      final newItem = CartItem.fromJson(response);
      _items.insert(0, newItem); // Adiciona no início
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar item: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    try {
      final response =
          await _client
              .from('cart')
              .update({'quantity': newQuantity})
              .eq('id', itemId)
              .select()
              .single();

      final updatedItem = CartItem.fromJson(response);
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar quantidade: $e');
      throw Exception('Erro ao atualizar quantidade');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _client
          .from('cart')
          .delete()
          .eq('id', itemId)
          .select(); // mantém para segurança

      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      print('Erro ao remover item: $e');
      throw Exception('Erro ao remover item');
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      await _client.from('cart').delete().eq('user_id', userId);

      _items.clear();
      notifyListeners();
    } catch (e) {
      print('Erro ao limpar carrinho: $e');
      throw Exception('Erro ao limpar carrinho');
    }
  }
}
