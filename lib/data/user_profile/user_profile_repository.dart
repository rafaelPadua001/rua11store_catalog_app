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
        'display_name':
            user.userMetadata?['name'] ??
            user.userMetadata?['display_name'] ??
            user.email?.split('@').first ??
            'Usuário',
      };
  print(authData);
      // Busca dados adicionais do perfil
      final profileResponse =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

    print(profileResponse);
      // Verifica se o perfil existe, se não, cria um novo
      if (profileResponse == null) {
        final newProfile = {
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
          'avatar_url': null,
          'full_name': user.userMetadata?['display_name'],
          'email': user.userMetadata?['email'],
        };

        await _supabase.from('user_profiles').insert(newProfile);
      }

      // Combina os dados
      final combinedData = {...authData, ...(profileResponse ?? {})};

      return UserModel.fromJson(combinedData);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

Future<UserModel> updateProfile(UserModel profile) async {
  try {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    // 1. Atualizar email no Auth (se alterado)
    if (currentUser.email != profile.email) {
      await _supabase.auth.updateUser(
        UserAttributes(email: profile.email),
      );
      debugPrint('Email de confirmação enviado para ${profile.email}');
    }

    // 2. Atualizar display_name no Auth (user_metadata)
    final currentDisplayName = currentUser.userMetadata?['display_name']?.toString();
    if (currentDisplayName != profile.full_name) {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'display_name': profile.full_name}),
      );
      debugPrint('Display name atualizado no Auth');
    }

    // 3. Preparar dados para user_profiles
    final profileData = {
      'full_name': profile.full_name, // Mapeia para o nome da coluna na tabela
      'email': profile.email,
      'birth_date': profile.birthDate?.toIso8601String(),
      'avatar_url': profile.avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 4. Atualizar user_profiles
    final response = await _supabase
        .from('user_profiles')
        .update(profileData)
        .eq('user_id', profile.id)
        .select()
        .single();

    // 5. Atualizar tabela public.users (se existir)
    try {
      await _supabase.from('users').update({
        'display_name': profile.full_name,
        'email': profile.email,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profile.id);
    } catch (e) {
      debugPrint('Ignorando atualização em public.users: $e');
    }

    return UserModel.fromJson(response);
  } catch (e) {
    debugPrint('Error updating user profile: $e');
    throw Exception('Falha ao atualizar perfil: ${e.toString()}');
  }
}
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Nome do arquivo único
      final fileName =
          'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Faz upload
      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      // Obtém URL pública
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Atualiza tanto na tabela auth.users quanto em user_profiles
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      await _supabase
          .from('user_profiles')
          .update({'avatar_url': imageUrl})
          .eq('user_id', userId);

      return imageUrl;
    } catch (e) {
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
        await _supabase.storage.from('avatars').remove([
          'avatar_$userId/$fileName',
        ]);
      }

      // Remove o perfil
      await _supabase.from('user_profiles').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      throw Exception('Failed to delete user profile');
    }
  }
}
