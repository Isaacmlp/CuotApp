import 'package:cuot_app/utils/validators.dart';
import 'package:cuot_app/widget/creditos/custom_textfield.dart';
import 'package:flutter/material.dart';

class ClienteForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onClienteInfoChanged;

  const ClienteForm({super.key, required this.onClienteInfoChanged});

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  // 🔧 LÓGICA: Validar y enviar datos del cliente
  void _validateAndSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onClienteInfoChanged({
        'nombreCompleto': _nombreController.text,
        'cedula': _cedulaController.text,
        'telefono': _telefonoController.text,
        'email': _emailController.text,
        'direccion': _direccionController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos del Cliente', 
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          
          // Nombre Completo
          CustomTextField(
            controller: _nombreController,
            label: 'Nombre Completo *',
            prefixIcon: Icons.person,
            validator: Validators.required,
            onChanged: (_) => _validateAndSubmit(),
          ),
          SizedBox(height: 12),
          
          // Cédula
          CustomTextField(
            controller: _cedulaController,
            label: 'Cédula *',
            prefixIcon: Icons.badge,
            keyboardType: TextInputType.number,
            validator: Validators.required,
            onChanged: (_) => _validateAndSubmit(),
          ),
          SizedBox(height: 12),
          
          // Teléfono
          CustomTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _validateAndSubmit(),
          ),
          SizedBox(height: 12),
          
          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            onChanged: (_) => _validateAndSubmit(),
          ),
          SizedBox(height: 12),
          
          // Dirección
          CustomTextField(
            controller: _direccionController,
            label: 'Dirección',
            prefixIcon: Icons.location_on,
            maxLines: 2,
            onChanged: (_) => _validateAndSubmit(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }
}