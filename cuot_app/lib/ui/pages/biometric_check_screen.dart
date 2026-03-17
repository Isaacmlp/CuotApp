// lib/screens/biometric_check_screen.dart
import 'package:cuot_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BiometricCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando autenticación...'),
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Autenticación Biométrica',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Coloca tu huella dactilar en el sensor\npara continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await authProvider.checkSavedSession();
                    if (authProvider.isAuthenticated) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  child: const Text('Intentar de nuevo'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Ir a login con credenciales
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Usar contraseña'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}