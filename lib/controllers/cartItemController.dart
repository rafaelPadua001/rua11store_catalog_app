import '../services/supabase_config.dart';
import '../models/cartItems.dart';

class Cartitemcontroller {
  final _supabase = SupabaseConfig.supabase;

  //fetch all itens on cart to cartId + userId
  Future<List<CartItem>> getCartItems(String cartId, String userId) async {
    final response = await _supabase
        .from('cart_items')
        .select()
        .eq('cart_id', cartId)
        .eq('user_id', userId);

    return (response as List).map((json) => CartItem.fromJson(json)).toList();
  }

  //Add new Item
  Future<CartItem?> addCartItem(CartItem item) async {
    final response =
        await _supabase
            .from('cart_items')
            .insert(item.toJson())
            .select()
            .single();

    return CartItem.fromJson(response);
  }

  Future<void> updateCartItemQantity(String id, int quantity) async {
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', id);
  }

  //Remove Unique item
  Future<void> removeCartItem(String id) async {
    await _supabase.from('cart_items').delete().eq('id', id);
  }

  //Remove all items
  Future<void> clearCart(String cartId) async {
    await _supabase.from('cart_items').delete().eq('cart_id', cartId);
  }
}
