// 📝 VISTA 2: Formulario para créditos en cuotas
import 'dart:io';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/utils/validators.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:cuot_app/widget/creditos/factura_uploader.dart';
import 'package:flutter/material.dart';

class FormularioPagounico extends StatefulWidget {
  final Function(Credito) onCreditoActualizado;
  final Function() onGuardar;

  const FormularioPagounico({
    super.key,
    required this.onCreditoActualizado,
    required this.onGuardar,
  });

  @override
  State<FormularioPagounico> createState() => _FormularioCuotasState();
}

class _FormularioCuotasState extends State<FormularioPagounico> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _conceptoController = TextEditingController();
  final _inversionController = TextEditingController();
  final _gananciaController = TextEditingController();
  final _cuotasController = TextEditingController();
  final _clienteController = TextEditingController();
  
  // Variables de estado
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaLimite = DateTime.now().add(Duration(days: 30));
  final ModalidadPago _modalidadSeleccionada = ModalidadPago.mensual;
  final bool _mostrarPersonalizado = false;
  
  // 🔧 NUEVO: Variable para almacenar la factura seleccionada
  File? _facturaSeleccionada;
  
  // Valores calculados
  double get _inversion => double.tryParse(_inversionController.text) ?? 0;
  double get _ganancia => double.tryParse(_gananciaController.text) ?? 0;
  double get _precioTotal => _inversion + _ganancia;
  int get _numCuotas => int.tryParse(_cuotasController.text) ?? 0;
  double get _valorCuota => _numCuotas > 0 ? _precioTotal / _numCuotas : 0;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔧 NUEVO: Widget de carga de factura 
            // Concepto/Producto
            TextFormField(
              controller: _conceptoController,
              decoration: InputDecoration(
                labelText: 'Concepto/Producto *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.required(v, 'Concepto'),
              onChanged: _actualizarCredito,
            ),
            SizedBox(height: 16),
            
            // Coste/Inversión
            TextFormField(
              controller: _inversionController,
              decoration: InputDecoration(
                labelText: 'Coste/Inversión  *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => Validators.positiveNumber(v, 'Inversión'),
              onChanged: _actualizarCredito,
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gananciaController,
                    decoration: InputDecoration(
                      labelText: 'Margen de ganancia *',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.positiveNumber(v, 'Ganancia'),
                    onChanged: _actualizarCredito,
                  ),
                ),
                // Número de cuotas
              ],
            ),
            SizedBox(height: 16),
            
            // Fecha de inicio
            Text('Fecha de inicio *', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            CustomDatePicker(
              selectedDate: _fechaInicio,
              onDateSelected: (date) {
                setState(() => _fechaInicio = date);
                _actualizarCredito();
              },
              label: 'Seleccionar fecha de inicio',
            ),
            SizedBox(height: 16),
            
            // Fecha límite de pago
            Text('Fecha límite de pago', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            CustomDatePicker(
              selectedDate: _fechaLimite,
              onDateSelected: (date) {
                setState(() => _fechaLimite = date);
                _actualizarCredito();
              },
              label: 'Seleccionar fecha límite',
            ),   
            
            SizedBox(height: 16),
            FacturaUploader(
              onFacturaSeleccionada: (File? archivo) {
                setState(() {
                  _facturaSeleccionada = archivo;
                });
                _actualizarCredito();
              },
            ),
            SizedBox(height: 24),
            
            // Modalidad de cobro
            Text('Modalidad de pago', style: TextStyle(fontWeight: FontWeight.w500)),
            // ... (aquí iría tu selector de modalidad)
            
            // Configuración personalizada (solo si se elige personalizado)
            if (_mostrarPersonalizado) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Configuración personalizada de cuotas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('(Funcionalidad en desarrollo)'),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Valores calculados automáticamente
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Precio total estimado:', '\$${_precioTotal.toStringAsFixed(2)}'),
                    Divider(),
                    _buildInfoRow('Valor Total:', '\$${_valorCuota.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Nombre del cliente
            TextFormField(
              controller: _clienteController,
              decoration: InputDecoration(
                labelText: 'Nombre del cliente *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Cliente 1, Juan Pérez, etc.',
              ),
              validator: (v) => Validators.required(v,'Cliente'),
              onChanged: _actualizarCredito,
            ),
            SizedBox(height: 16),
            
            // 🔧 NUEVO: Mostrar resumen de factura seleccionada
            if (_facturaSeleccionada != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura adjunta:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _facturaSeleccionada!.path.split('/').last,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarCredito,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('GUARDAR CRÉDITO', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _actualizarCredito([_]) {
    if (_formKey.currentState?.validate() ?? false) {
      final credito = Credito(
        concepto: _conceptoController.text,
        costeInversion: _inversion,
        margenGanancia: _ganancia,
        fechaInicio: _fechaInicio,
        modalidadPago: _modalidadSeleccionada,
        nombreCliente: _clienteController.text,
        numeroCuotas: _numCuotas,
        facturaPath: _facturaSeleccionada?.path,
      );
      widget.onCreditoActualizado(credito);
    }
  }
  
  void _guardarCredito() {
    if (_formKey.currentState?.validate() ?? false) {
      // 🔧 NUEVO: Verificar si hay factura antes de guardar (opcional)
      if (_facturaSeleccionada == null) {
        _mostrarDialogoFacturaOpcional();
      } else {
        widget.onGuardar();
      }
    }
  }
  
  // 🔧 NUEVO: Diálogo para factura opcional
  void _mostrarDialogoFacturaOpcional() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Adjuntar factura?'),
        content: Text('No has adjuntado ninguna factura. ¿Deseas continuar sin factura?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Abrir el FacturaUploader
              // (El FacturaUploader ya está visible arriba)
            },
            child: Text('ADJUNTAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onGuardar(); // Continuar sin factura
            },
            child: Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }
  
  String _getModalidadText(ModalidadPago modalidad) {
    switch (modalidad) {
      case ModalidadPago.diario: return 'Diario';
      case ModalidadPago.semanal: return 'Semanal';
      case ModalidadPago.quincenal: return 'Quincenal';
      case ModalidadPago.mensual: return 'Mensual';
      case ModalidadPago.personalizado: return 'Personalizado';
    }
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  @override
  void dispose() {
    _conceptoController.dispose();
    _inversionController.dispose();
    _gananciaController.dispose();
    _cuotasController.dispose();
    _clienteController.dispose();
    super.dispose();
  }
}