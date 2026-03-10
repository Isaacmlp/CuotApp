import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfiguracion {
  // Método para cargar el .env (debe llamarse primero)
  static Future<void> cargar() async {
    await dotenv.load(fileName: "../../.env");
  }

  // Getters con verificación
  static String get url {
    _verificarCargado();
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get anonKey {
    _verificarCargado();
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static void _verificarCargado() {
    if (!dotenv.isInitialized) {
      throw Exception('⛔ Error: El archivo .env no ha sido cargado. Debes llamar a SupabaseConfiguracion.cargar() en main.dart antes de usar las variables.');
    }
  }

  // Método de prueba
  static void imprimirConfiguracion() {
    print('📁 Configuración cargada:');
    print('URL: ${dotenv.env['SUPABASE_URL']}');
    print('Key: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');
  }
}