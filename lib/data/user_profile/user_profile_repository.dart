import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../models/user.dart';

class UserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepository({SupabaseClient? supabase}) 
    : _supabase = supabase ?? Supabase.instance.client;
    
   String _parseDateToString(dynamic date) {
  if (date is DateTime) {
    return date.toIso8601String();
  } else if (date is String) {
    return date; // Já está no formato string
  }
  return DateTime.now().toIso8601String(); // Fallback
} 

  Future<UserModel?> getProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Busca dados básicos de autenticação
      final authData = {
  'id': user.id,
  'email': user.email,
  'created_at': _parseDateToString(user.createdAt),
  'display_name': user.userMetadata?['name'] ?? 
                 user.userMetadata?['displayname'] ??
                 user.email?.split('@').first ?? 'Usuário',
};

      // Busca dados adicionais do perfil
      final profileResponse = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

      // Verifica se o perfil existe, se não, cria um novo
      if (profileResponse == null) {
        final newProfile = {
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
          'avatar_url': null,
        };
        
        await _supabase
          .from('user_profiles')
          .insert(newProfile);
      }

      // Combina os dados
      final combinedData = {
        ...authData,
        ...(profileResponse ?? {}),
      };

      return UserModel.fromJson(combinedData);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserModel> updateProfile(UserModel profile) async {
    try {
      final response = await _supabase
        .from('user_profiles')
        .update(profile.toJson())
        .eq('user_id', profile.id)
        .select()
        .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Verifica se o perfil existe
      var profile = await getProfile();
      if (profile == null) {
        // Cria um perfil básico se não existir
        profile = UserModel(
          id: userId,
          email: _supabase.auth.currentUser?.email ?? '',
          createdAt: DateTime.now(),
        );
        await _supabase
          .from('user_profiles')
          .insert(profile.toJson());
      }

      // Nome do arquivo
      final fileName = 'avatar_$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Faz upload da imagem
      await _supabase.storage
          .from('avatars')
          .upload(
            fileName, 
            imageFile,
            fileOptions: FileOptions(contentType: 'image/jpeg')
          );

      // Obtém URL pública
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Atualiza o perfil do usuário
      final response = await _supabase
          .from('user_profiles') // Corrigido para usar a mesma tabela
          .update({'avatar_url': imageUrl})
          .eq('user_id', userId)
          .select()
          .single();

      if (response == null) {
        throw Exception('Failed to update profile with new avatar');
      }

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception('Falha ao enviar avatar: ${e.toString()}');
    }
  }

  Future<void> deleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Remove o avatar do storage primeiro
      final profile = await getProfile();
      if (profile?.avatarUrl != null) {
        final fileName = profile!.avatarUrl!.split('/').last;
        await _supabase.storage
          .from('avatars')
          .remove(['avatar_$userId/$fileName']);
      }

      // Remove o perfil
      await _supabase
        .from('user_profiles')
        .delete()
        .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      throw Exception('Failed to delete user profile');
    }
  }
}