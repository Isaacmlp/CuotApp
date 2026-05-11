// lib/widget/creditos/selector_fechas_cuotas_horizontal.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/widget/creditos/editor_cuota_horizontal.dart';

class SelectorFechasCuotasHorizontal extends StatefulWidget {
  final int numeroCuotas;
  final DateTime fechaInicio;
  final double montoPorCuota;
  final Function(List<CuotaPersonalizada>) onFechasSeleccionadas;

  const SelectorFechasCuotasHorizontal({
    super.key,
    required this.numeroCuotas,
    required this.fechaInicio,
    required this.montoPorCuota,
    required this.onFechasSeleccionadas,
  });

  @override
  State<SelectorFechasCuotasHorizontal> createState() => _SelectorFechasCuotasHorizontalState();
}

class _SelectorFechasCuotasHorizontalState extends State<SelectorFechasCuotasHorizontal> {
  late List<CuotaPersonalizada> _cuotas;
  late DateTime _fechaBase;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inicializarCuotas();
  }

  void _inicializarCuotas() {
    _fechaBase = widget.fechaInicio;
    _cuotas = List.generate(widget.numeroCuotas, (index) {
      return CuotaPersonalizada(
        numeroCuota: index + 1,
        fechaPago: _fechaBase.add(Duration(days: 30 * (index + 1))), // Por defecto mensual
        monto: widget.montoPorCuota,
      );
    });
  }

  void _actualizarCuota(CuotaPersonalizada cuotaEditada) {
    setState(() {
      final index = _cuotas.indexWhere((c) => c.numeroCuota == cuotaEditada.numeroCuota);
      if (index != -1) {
        _cuotas[index] = cuotaEditada;
      }
    });
    widget.onFechasSeleccionadas(_cuotas);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instrucciones
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Desliza horizontalmente para ver todas las cuotas. '
                  'Toca el lápiz para editar fecha y monto.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista horizontal de cuotas
        SizedBox(
          height: 200, // Altura fija para la lista horizontal
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _cuotas.length,
            itemBuilder: (context, index) {
              return EditorCuotaHorizontal(
                cuota: _cuotas[index],
                onCuotaEditada: _actualizarCuota,
                primaryColor: primaryColor,
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botones de acción rápida
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAccionRapida(
              icon: Icons.calendar_today,
              label: 'Todas mensual',
              onTap: () {
                setState(() {
                  for (var i = 0; i < _cuotas.length; i++) {
                    _cuotas[i] = _cuotas[i].copyWith(
                      fechaPago: widget.fechaInicio.add(Duration(days: 30 * (i + 1))),
                    );
                  }
                });
                widget.onFechasSeleccionadas(_cuotas);
              },
            ),
            _buildAccionRapida(
              icon: Icons.attach_money,
              label: 'Monto igual',
              onTap: () {
                setState(() {
                  for (var i = 0; i < _cuotas.length; i++) {
                    _cuotas[i] = _cuotas[i].copyWith(
                      monto: widget.montoPorCuota,
                    );
                  }
                });
                widget.onFechasSeleccionadas(_cuotas);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccionRapida({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}