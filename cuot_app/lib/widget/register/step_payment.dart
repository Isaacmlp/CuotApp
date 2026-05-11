import 'package:flutter/material.dart';

class StepPayment extends StatelessWidget {
  const StepPayment({
    super.key,
    required this.formKey,
    required this.metodoPago,
    required this.onMetodoPagoChanged,
    required this.detallesPagoCtrl,
    required this.primaryGreen,
  });

  final GlobalKey<FormState> formKey;
  final String metodoPago;
  final ValueChanged<String?> onMetodoPagoChanged;
  final TextEditingController detallesPagoCtrl;
  final Color primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tu método de pago principal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: metodoPago,
            items: const [
              DropdownMenuItem(
                value: 'Transferencia',
                child: Text('Transferencia bancaria'),
              ),
              DropdownMenuItem(
                value: 'PagoMóvil',
                child: Text('Pago móvil'),
              ),
              DropdownMenuItem(
                value: 'Tarjeta',
                child: Text('Tarjeta de débito/crédito'),
              ),
              DropdownMenuItem(
                value: 'Efectivo',
                child: Text('Efectivo'),
              ),
            ],
            onChanged: onMetodoPagoChanged,
            decoration: _inputDecoration(
              context,
              'Método de pago',
              Icons.payments_outlined,
              primaryGreen,
            ),
            validator: (v) =>
                v == null ? 'Selecciona un método de pago' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: detallesPagoCtrl,
            decoration: _inputDecoration(
              context,
              'Detalles (Banco, titular, etc.)',
              Icons.description_outlined,
              primaryGreen,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Podrás editar tus métodos de pago luego desde tu perfil.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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

