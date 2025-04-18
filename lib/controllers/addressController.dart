import '../models/adress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressController {
  final _supabase = Supabase.instance.client;
  final userId = Supabase.instance.client.auth.currentUser!.id;


 Future<void> insertAddress(Map<String, dynamic> addressData) async {
  try {
    final response = await Supabase.instance.client
        .from('addresses')
        .insert(addressData);

    print('Endereço salvo com sucesso: $response');
  } catch (e) {
    print('Erro ao salvar endereço: $e');
  }
}

  Future<void> updateAddress(int id, Address address) async {
    final response = await _supabase
        .from('addresses')
        .update(address.toJson())
        .eq('id', id);

    if (response.error != null) {
      throw Exception('Erro ao atualizar: ${response.error!.message}');
    }
  }

  Future<void> deleteAddress(int id) async {
    final response = await _supabase.from('addresses').delete().eq('id', id);

    if (response.error != null) {
      throw Exception('Erro ao remover: ${response.error!.message}');
    }
  }

  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final data = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId); // Supabase Auth usa UUID (String)

      return (data as List).map((json) => Address.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Erro ao buscar endereços: $error');
    }
  }
}
