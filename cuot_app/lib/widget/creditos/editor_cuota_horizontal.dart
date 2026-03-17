// lib/widget/creditos/editor_cuota_horizontal.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';

class EditorCuotaHorizontal extends StatefulWidget {
  final CuotaPersonalizada cuota;
  final Function(CuotaPersonalizada) onCuotaEditada;
  final Color primaryColor;

  const EditorCuotaHorizontal({
    super.key,
    required this.cuota,
    required this.onCuotaEditada,
    required this.primaryColor,
  });

  @override
  State<EditorCuotaHorizontal> createState() => _EditorCuotaHorizontalState();
}

class _EditorCuotaHorizontalState extends State<EditorCuotaHorizontal> {
  late DateTime _fechaSeleccionada;
  late TextEditingController _montoController;
  bool _modoEdicion = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.cuota.fechaPago;
    _montoController = TextEditingController(text: widget.cuota.monto.toStringAsFixed(2));
  }

  void _guardarCambios() {
    final nuevoMonto = double.tryParse(_montoController.text) ?? widget.cuota.monto;
    
    final cuotaEditada = widget.cuota.copyWith(
      fechaPago: _fechaSeleccionada,
      monto: nuevoMonto,
    );
    
    widget.onCuotaEditada(cuotaEditada);
    setState(() {
      _modoEdicion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      width: 280, // Ancho fijo para cada tarjeta horizontal
      child: Card(
        elevation: _modoEdicion ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _modoEdicion
              ? BorderSide(color: widget.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado con número de cuota y botón editar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cuota #${widget.cuota.numeroCuota}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!_modoEdicion)
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() {
                          _modoEdicion = true;
                        });
                      },
                    ),
                  if (_modoEdicion)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, size: 18, color: Colors.green),
                          onPressed: _guardarCambios,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _modoEdicion = false;
                              _fechaSeleccionada = widget.cuota.fechaPago;
                              _montoController.text = widget.cuota.monto.toStringAsFixed(2);
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Contenido según modo
              if (!_modoEdicion) ...[
                // Vista normal
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFecha(_fechaSeleccionada),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '\$${widget.cuota.monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Modo edición
                // Editor de fecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      CustomDatePicker(
                        selectedDate: _fechaSeleccionada,
                        onDateSelected: (date) {
                          setState(() {
                            _fechaSeleccionada = date;
                          });
                        },
                        label: 'Seleccionar',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Editor de monto
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monto:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _montoController,
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
           '${fecha.month.toString().padLeft(2, '0')}/'
           '${fecha.year}';
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }
}