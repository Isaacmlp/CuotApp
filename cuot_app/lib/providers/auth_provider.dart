import 'package:cuot_app/service/biometric_auth_service.dart';
import 'package:cuot_app/service/secure_storage_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final BiometricAuthService _biometricService = BiometricAuthService();
  final SecureStorageService _storageService = SecureStorageService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Verificar si hay una sesión guardada
  Future<void> checkSavedSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storageService.getUserToken();
      final biometricEnabled = await _storageService.isBiometricEnabled();

      if (token != null && biometricEnabled) {
        // Verificar si hay biometría disponible
        final isAvailable = await _biometricService.isBiometricAvailable();
        
        if (isAvailable) {
          // Intentar autenticar con biometría
          final authenticated = await _biometricService.authenticateWithBiometrics();
          
          if (authenticated) {
            _isAuthenticated = true;
            _errorMessage = null;
          } else {
            _errorMessage = 'Autenticación biométrica fallida';
          }
        } else {
          _errorMessage = 'Biometría no disponible en este dispositivo';
        }
      }
    } catch (e) {
      _errorMessage = 'Error verificando sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Iniciar sesión con credenciales
  Future<bool> loginWithCredentials(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Aquí iría tu lógica de autenticación con backend
      // Simulamos una autenticación exitosa
      if (username.isNotEmpty && password.isNotEmpty) {
        // Guardar token de ejemplo
        await _storageService.saveUserCredentials('dummy_token_123');
        
        // Preguntar si quiere habilitar biometría
        // Esto se manejaría en la UI
        _isAuthenticated = true;
        return true;
      } else {
        _errorMessage = 'Credenciales inválidas';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error en inicio de sesión: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Habilitar biometría
  Future<bool> enableBiometric() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      
      if (isAvailable) {
        final authenticated = await _biometricService.authenticateWithBiometrics();
        
        if (authenticated) {
          // Actualizar el estado en secure storage
          await _storageService.saveUserCredentials(
            await _storageService.getUserToken() ?? '',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error habilitando biometría: $e');
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _storageService.clearUserCredentials();
    _isAuthenticated = false;
    notifyListeners();
  }
}