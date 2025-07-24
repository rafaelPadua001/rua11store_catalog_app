import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryPasswordController {
  final baseUrl = dotenv.env['API_URL_LOCAL'] ?? '';

  Future<bool> sendRecoveryEmail(BuildContext context, String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }
}
