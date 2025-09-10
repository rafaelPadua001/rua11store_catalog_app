import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_config.dart';

class RegisterDeviceToken {
  static Future<void> registerDeviceToken(String userId) async {
    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();

    if (token != null) {
      // print('Token do dispositivo: $token');

      //save on supabase
      await SupabaseConfig.supabase.from('user_devices').upsert({
        'user_id': userId,
        'device_token': token,
      });

      // print('Token registrado com supabase');
    }
  }
}
