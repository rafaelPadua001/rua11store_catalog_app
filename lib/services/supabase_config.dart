import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = "https://ofsvexzxfrlixkvgppjf.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mc3ZleHp4ZnJsaXhrdmdwcGpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0NTI3MDQsImV4cCI6MjA4MzAyODcwNH0.waWRQiBSe5KvRA0eXWlYfz4B3_Tg65obGbSlz3Po_XQ";

  // Acesse o cliente Supabase através do Supabase.instance.client
  static SupabaseClient get supabase => Supabase.instance.client;
}
