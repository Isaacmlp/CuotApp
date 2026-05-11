// lib/widget/creditos/dialogo_editar_cuota.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';

class DialogoEditarCuota extends StatefulWidget {
  final CuotaPersonalizada cuota;
  final Color primaryColor;

  const DialogoEditarCuota({
    super.key,
    required this.cuota,
    required this.primaryColor,
  });

  @override
  State<DialogoEditarCuota> createState() => _DialogoEditarCuotaState();
}

class _DialogoEditarCuotaState extends State<DialogoEditarCuota> {
  late DateTime _fechaSeleccionada;
  late TextEditingController _montoController;
  bool _fechaModificada = false;
  bool _montoModificado = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.cuota.fechaPago;
    _montoController = TextEditingController(
      text: widget.cuota.monto.toStringAsFixed(2),
    );
    
    // Listeners para detectar cambios
    _montoController.addListener(() {
      final nuevoMonto = double.tryParse(_montoController.text) ?? 0;
      setState(() {
        _montoModificado = (nuevoMonto - widget.cuota.monto).abs() > 0.01;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final huboCambios = _fechaModificada || _montoModificado;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              widget.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con diseño mejorado
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_calendar,
                      color: widget.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar Cuota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '#${widget.cuota.numeroCuota}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Selector de fecha con indicador de cambio
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _fechaModificada 
                      ? widget.primaryColor 
                      : Colors.grey.shade300,
                  width: _fechaModificada ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _fechaModificada 
                            ? widget.primaryColor 
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha de pago',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: _fechaModificada 
                              ? widget.primaryColor 
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (_fechaModificada) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomDatePicker(
                    selectedDate: _fechaSeleccionada,
                    onDateSelected: (date) {
                      setState(() {
                        _fechaSeleccionada = date;
                        _fechaModificada = date != widget.cuota.fechaPago;
                      });
                    },
                    label: 'Seleccionar fecha',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Campo de monto con indicador de cambio
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _montoModificado 
                      ? widget.primaryColor 
                      : Colors.grey.shade300,
                  width: _montoModificado ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: _montoModificado 
                            ? widget.primaryColor 
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Monto',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: _montoModificado 
                              ? widget.primaryColor 
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (_montoModificado) ...[
                        const Spacer(),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(
                        color: widget.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones con diseño mejorado
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final nuevoMonto = double.tryParse(_montoController.text);
                      if (nuevoMonto == null || nuevoMonto <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Ingresa un monto válido'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }
                      
                      final cuotaEditada = widget.cuota.copyWith(
                        fechaPago: _fechaSeleccionada,
                        monto: nuevoMonto,
                      );
                      
                      Navigator.pop(context, cuotaEditada);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: huboCambios ? 4 : 2,
                    ),
                    child: Text(huboCambios ? 'GUARDAR CAMBIOS' : 'GUARDAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }
}