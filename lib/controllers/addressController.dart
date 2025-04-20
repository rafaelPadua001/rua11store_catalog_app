import '../models/adress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressController {
  final _supabase = Supabase.instance.client;
  final userId = Supabase.instance.client.auth.currentUser!.id;
  List<Map<String, dynamic>> addresses = [];

Future<Map<String, dynamic>?> insertAddress(Map<String, dynamic> addressData) async {
  try {
    final response = await Supabase.instance.client
        .from('addresses')
        .insert(addressData)
        .select()
        .single(); // importante!

    print('Endereço salvo com sucesso: $response');

    addresses.add(response); // adiciona localmente se quiser

    return response; // retorna o endereço inserido
  } catch (e) {
    print('Erro ao salvar endereço: $e');
    return null;
  }
}



Future<bool> updateAddress(int addressId, Map<String, dynamic> addressData) async {
  try {
    // Realiza a atualização no Supabase
    final response = await _supabase
        .from('addresses')
        .update(addressData)
        .eq('id', addressId)
        .select()
        .single();

    print('Resposta do Supabase: $response');

    // Verifica se a resposta está nula ou mal formada
    if (response == null) {
      print('Erro: A resposta do Supabase é nula');
      return false; // Retorna false se a resposta for nula
    }

    // Verifica se a resposta contém dados atualizados
    if (response.isNotEmpty) {
      print('Endereço atualizado com sucesso!');
      return true; // Retorna true se a atualização foi bem-sucedida
    } else {
      // Se não houver dados na resposta
      print('Nenhum dado retornado após a atualização.');
      return false; // Retorna false se não houver dados ou se a atualização falhou
    }
  } catch (e) {
    // Captura qualquer outro erro inesperado
    print('Erro inesperado ao atualizar o endereço: $e');
    return false; // Retorna false se ocorrer uma exceção
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
