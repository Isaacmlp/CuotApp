// lib/services/biometric_auth_service.dart
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Verificar si el dispositivo soporta biometría
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      // Obtener tipos de biometría disponibles
      final biometrics = await _localAuth.getAvailableBiometrics();
      
      // Verificar si hay algún tipo de biometría (huella o reconocimiento facial)
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      print('Error verificando biometría: $e');
      return false;
    }
  }

  // Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error obteniendo biometrías: $e');
      return [];
    }
  }

  // Autenticar con biometría
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Por favor autentícate para acceder a la aplicación',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } on PlatformException catch (e) {
      print('Error en autenticación: $e');
      return false;
    }
  }

  // Detener autenticación
  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}