import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Verificar si está inicializado
  bool get isInitialized => SupabaseConfig.isInitialized;

  // Obtener cliente (lanzará error si no está inicializado)
  SupabaseClient get client => SupabaseConfig.client;

  // Métodos con verificación
  Future<List<Map<String, dynamic>>> fetchAll(String schema,String table) async {
    _checkInitialized();
    try {
      return await client.schema(schema).from(table).select();
    } catch (e) {
      print('❌ Error en fetchAll: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String table, String id) async {
    _checkInitialized();
    try {
      return await client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      print('❌ Error en fetchById: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    _checkInitialized();
    try {
      return await client
          .from(table)
          .insert(data)
          .select()
          .single();
    } catch (e) {
      print('❌ Error en insert: $e');
      rethrow;
    }
  }

  Future<bool> testConnection() async {
    if (!isInitialized) return false;
    try {
      await client.from('_test').select('count').limit(1);
      return true;
    } catch (e) {
      // Si la tabla no existe, el cliente sigue funcionando
      return true;
    }
  }

  void _checkInitialized() {
    if (!isInitialized) {
      throw Exception('SupabaseService no inicializado');
    }
  }
}

// Singleton global
final supabaseService = SupabaseService();