import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cart.dart';

class CartRepository {
  final SupabaseClient _client;

  CartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<List<CartItem>> getCartItems(String userId) async {
    final response = await _client
      .from('cart')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

      return (response as List)
        .map((item) => CartItem.fromJson(item))
        .toList();

  }

  Future<CartItem> addItem(CartItem item) async {
  try {
    // Remove o ID antes de inserir (o Supabase vai gerar um novo)
    final itemToInsert = item.toJson()..remove('id');
    
    final response = await _client
      .from('cart')
      .insert(itemToInsert)
      .select()
      .single();

    return CartItem.fromJson(response);
  } catch (e) {
    print(e.toString());
    throw Exception('Failed to add item to cart: ${e.toString()}');
  }
}

  Future<CartItem> updateQuantity(String itemId, int newQuantity) async {
    final response = await _client
      .from('cart')
      .update({'quantity': newQuantity})
      .eq('id', itemId)
      .select()
      .single();

    return CartItem.fromJson(response);
  }

Future<bool> removeItem(String itemId) async {
  try {
    final response = await _client
      .from('cart')
      .delete()
      .eq('id', itemId)
      .select();  // Adicione .select() para obter a resposta
    
    // No Supabase, a resposta é uma lista dos itens removidos
    return response.isNotEmpty;
  } catch (e) {
    print('Erro ao remover item: $e');
    return false;
  }
}
  Future<void> clearCart(String userId) async {
    await _client
      .from('cart')
      .delete()
      .eq('user_id', userId);
  }

}