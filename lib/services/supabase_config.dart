import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = "https://hkoiwompbdeldmoznpxc.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhrb2l3b21wYmRlbGRtb3pucHhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MTI5NzIsImV4cCI6MjA1ODQ4ODk3Mn0.LwF_Rcm4zK8F1RC5kfuoR9eZdr5SvWcQuPSY0cpjq7U";

  // Acesse o cliente Supabase através do Supabase.instance.client
  static SupabaseClient get supabase => Supabase.instance.client;
}