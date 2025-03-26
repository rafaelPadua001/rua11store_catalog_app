import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../models/user.dart';

class UserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepository({SupabaseClient? supabase}) 
    : _supabase = supabase ?? Supabase.instance.client;

  Future<UserModel?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserModel> createProfile(UserModel profile) async {
    try {
      final response = await _supabase
        .from('user_profiles')
        .insert(profile.toJson())
        .select()
        .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      throw Exception('Failed to create user profile');
    }
  }

  Future<UserModel> updateProfile(UserModel profile) async {
    try {
      final response = await _supabase
        .from('user_profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
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
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileExtension = imageFile.path.split('.').last;
      final fileName = 'user_$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage
        .from('avatars')
        .upload(fileName, imageFile);

      return _supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      throw Exception('Failed to upload avatar');
    }
  }

  Future<void> deleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

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