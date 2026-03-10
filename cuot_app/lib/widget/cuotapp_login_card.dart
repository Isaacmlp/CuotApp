import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';
import 'package:cuot_app/widget/login_form.dart';
import 'package:flutter/material.dart';
import 'cuotapp_social_buttons_row.dart';

class CuotAppLoginCard extends StatefulWidget {
  final Color primaryGreen;
  
  const CuotAppLoginCard({super.key, required this.primaryGreen});

  @override
  State<CuotAppLoginCard> createState() => _CuotAppLoginCardState();
}

class _CuotAppLoginCardState extends State<CuotAppLoginCard> {
  // ✅ Crear el LoginForm como variable de instancia
  final LoginForm _loginForm = LoginForm();
  
  // ✅ Variables para manejar estado de carga
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _iniciarSesion() async {
    // Ocultar teclado
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1️⃣ Obtener datos del formulario
      
      final String correo = _loginForm.obtenerCorreo();
      final String contrasena = _loginForm.obtenerContrasena();

      if (correo.isEmpty || contrasena.isEmpty) {
        throw Exception('Por favor completa todos los campos');
      }

      print('📧 Intentando login con: $correo');

      // 2️⃣ Consultar Supabase (versión corregida)
      final supabaseService = SupabaseService();
      
      // 👁️ NOTA: Ajusta el nombre de la tabla según tu BD
      // Si la tabla se llama "Credenciales" en schema "Usuarios"
      final usuarios = await supabaseService.client
          .schema('Usuarios')  // Si está en schema Usuarios
          .from('Credenciales')  // Nombre de la tabla
          .select()
          .eq('Correo_Electronico', correo)
          .maybeSingle();  // Obtener un solo registro

      // 3️⃣ Verificar credenciales
      if (usuarios == null) {
        throw Exception('Usuario no encontrado');
      }

      final contrasenaBD = usuarios['Contrasena'] ?? '';
      
      if (contrasena == contrasenaBD) {
        print('✅ Login exitoso para: $correo');
        final user = await supabaseService.client.schema("Usuarios").from("Usuarios").select("Nombre_Completo").eq('Correo_Electronico', correo).maybeSingle();
        String nombre;

        nombre = (user?['Nombre_Completo']);

        for (var i = 0; i < nombre.length; i++) {
          if (nombre[i] == '{'){
            nombre = "";
          }
          if (nombre[i] == '}'){
            nombre = "";
          } 
        }

        // Aquí puedes guardar la sesión, navegar a otra pantalla, etc.
        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen(correo: correo, userName: nombre)),
            );
          
         // TODO: Navegar a la pantalla principal
          // Navigator.pushReplacement(...)
        }
      } else {
        throw Exception('Contraseña incorrecta');
      }

    } catch (e) {
      print('❌ Error en login: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '');
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicia sesión',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: _loginForm.getCorreo(),  // ✅ Acceso directo
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: widget.primaryGreen, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            obscureText: true,
            controller: _loginForm.getContrasena(),  // ✅ Acceso directo
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: widget.primaryGreen, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mensaje de error (si existe)
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: widget.primaryGreen,
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 8),

          // Botón de entrada
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _iniciarSesion,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Entrar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey[200])),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('o continúa con', style: TextStyle(fontSize: 12)),
              ),
              Expanded(child: Container(height: 1, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(height: 14),

          const CuotAppSocialButtonsRow(),
        ],
      ),
    );
  }
}