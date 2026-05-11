import 'package:cuot_app/core/supabase/supabase_credential.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static final SupabaseConfig _instance = SupabaseConfig._internal();
  factory SupabaseConfig() => _instance;
  SupabaseConfig._internal();

  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      
      await Supabase.initialize(
        url: SupabaseConfiguracion.url,  
        anonKey: SupabaseConfiguracion.anonKey,    
      );
      
      _isInitialized = true;
      print('✅ Supabase inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('Supabase no inicializado. Llama a initialize() primero.');
    }
    return Supabase.instance.client;
  }

  static bool get isInitialized => _isInitialized;
}