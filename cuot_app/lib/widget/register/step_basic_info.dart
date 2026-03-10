import 'package:flutter/material.dart';

class StepBasicInfo extends StatelessWidget {
  const StepBasicInfo({
    super.key,
    required this.formKey,
    required this.nombreCtrl,
    required this.emailCtrl,
    required this.telefonoCtrl,
    required this.cedulaCtrl,
    required this.contrasenaCtrl,
    required this.contrasenaVerificaCtrl,
    required this.primaryGreen,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telefonoCtrl;
  final TextEditingController cedulaCtrl;
  final TextEditingController contrasenaCtrl;
  final TextEditingController contrasenaVerificaCtrl;
  final Color primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nombreCtrl,
            decoration: _inputDecoration(
              context,
              'Nombre completo',
              Icons.person,
              primaryGreen,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailCtrl,
            decoration: _inputDecoration(
              context,
              'Correo electrónico',
              Icons.email_outlined,
              primaryGreen,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!v.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: telefonoCtrl,
            decoration: _inputDecoration(
              context,
              'Teléfono',
              Icons.phone,
              primaryGreen,
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu teléfono' : null
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cedulaCtrl,
            decoration: _inputDecoration(
              context,
              'Cedula',
              Icons.perm_identity,
              primaryGreen,
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu Cedula' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contrasenaCtrl,

            decoration: _inputDecoration(
              context,
              'Contraseña',
              Icons.password,
              primaryGreen,
            ),
            obscureText: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa tu Contraseña' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contrasenaVerificaCtrl,

            decoration: _inputDecoration(
              context,
              'Verifica tu Contraseña',
              Icons.password,
              primaryGreen,
            ),
            obscureText: true,
            validator: (v) =>
                ((v == null || v.trim().isEmpty) && (v == contrasenaCtrl.text)) ? 'La contraseña no coincide' : null,
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label,
    IconData icon,
    Color primaryGreen,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
        borderSide: BorderSide(color: primaryGreen, width: 1.6),
      ),
    );
  }
}
