import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Guardar token/credencial
  Future<void> saveUserCredentials(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'biometric_enabled', value: 'true');
  }

  // Obtener token
  Future<String?> getUserToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Verificar si el usuario tiene biometría habilitada
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // Limpiar credenciales (logout)
  Future<void> clearUserCredentials() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'biometric_enabled');
  }
}