import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/user_admin_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/utils/network_utils.dart';
import 'package:flutter/material.dart';

class CrearUsuarioPage extends StatefulWidget {
  final String creadoPor;

  const CrearUsuarioPage({
    super.key,
    required this.creadoPor,
  });

  @override
  State<CrearUsuarioPage> createState() => _CrearUsuarioPageState();
}

class _CrearUsuarioPageState extends State<CrearUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final UserAdminService _userService = UserAdminService();
  final BitacoraService _bitacoraService = BitacoraService();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();
  final TextEditingController _confirmarCtrl = TextEditingController();

  String _rolSeleccionado = 'cliente';
  bool _isCreating = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _cedulaCtrl.dispose();
    _contrasenaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_contrasenaCtrl.text != _confirmarCtrl.text) {
      _showSnackBar('Las contraseñas no coinciden', Colors.red);
      return;
    }

    setState(() => _isCreating = true);

    if (!await NetworkUtils.hasInternetConnection()) {
      setState(() => _isCreating = false);
      _showSnackBar('Sin conexión a internet', Colors.red);
      return;
    }

    try {
      final usuario = await _userService.crearUsuario(
        nombre: _nombreCtrl.text.trim(),
        correo: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        contrasena: _contrasenaCtrl.text,
        rol: _rolSeleccionado,
        creadoPor: widget.creadoPor,
      );

      await _bitacoraService.registrarActividad(
        usuarioNombre: widget.creadoPor,
        accion: 'crear_usuario',
        descripcion: 'Creó usuario ${usuario.nombreCompleto} con rol $_rolSeleccionado',
        entidadId: usuario.id,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final friendlyError = NetworkUtils.getFriendlyErrorMessage(e);
        _showSnackBar('❌ $friendlyError', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.veryLightGreen,
                        child: const Icon(
                          Icons.person_add,
                          size: 36,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nuevo Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Creado por: ${widget.creadoPor}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Campos del formulario
                _buildField(
                  controller: _nombreCtrl,
                  label: 'Nombre completo',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _emailCtrl,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (!v.contains('@')) return 'Email no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _telefonoCtrl,
                  label: 'Teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                
                _buildField(
                  controller: _cedulaCtrl,
                  label: 'Cédula / ID',
                  icon: Icons.badge_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _contrasenaCtrl,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 4) return 'Mínimo 4 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _confirmarCtrl,
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_outline,
                  obscureText: !_showPassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v != _contrasenaCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Rol del usuario',
                      icon: Icon(Icons.badge_outlined),
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('🔰 Administrador')),
                      DropdownMenuItem(value: 'supervisor', child: Text('👔 Supervisor')),
                      DropdownMenuItem(value: 'empleado', child: Text('👷 Empleado')),
                      DropdownMenuItem(value: 'cliente', child: Text('👤 Cliente')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _rolSeleccionado = value);
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Botón crear
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _crearUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CREAR USUARIO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
