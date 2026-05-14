import 'package:cuot_app/Model/bitacora_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BitacoraPage extends StatefulWidget {
  final String nombreUsuario;

  const BitacoraPage({super.key, required this.nombreUsuario});

  @override
  State<BitacoraPage> createState() => _BitacoraPageState();
}

class _BitacoraPageState extends State<BitacoraPage> {
  final BitacoraService _bitacoraService = BitacoraService();
  List<BitacoraActividad> _actividades = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // 1. Obtener los empleados afiliados a este Admin
      final asignaciones = await CreditoCompartidoService().obtenerCreditosCompartidosPorPropietario(widget.nombreUsuario);
      final listEmpleados = asignaciones.map((a) => a.trabajadorNombre).toSet().toList();
      final List<String> filtros = [widget.nombreUsuario, ...listEmpleados];

      final acts = await _bitacoraService.obtenerActividades(
        limit: 100,
        usuariosFilter: filtros,
      );
      if (mounted) {
        setState(() {
          _actividades = acts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Bitácora de Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarActividades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security, size: 60, color: AppColors.error),
                        const SizedBox(height: 16),
                        const Text(
                          'Permiso Denegado',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Parece que necesitas configurar los permisos RLS en Supabase para la tabla Bitacora_Actividad.\n\nDetalle: $_errorMessage',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                )
              : _actividades.isEmpty
                  ? const Center(child: Text('No hay actividad registrada'))
                  : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _actividades.length,
                  itemBuilder: (context, index) {
                    final a = _actividades[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAccionColor(a.accion).withOpacity(0.1),
                          child: Icon(_getAccionIcon(a.accion), color: _getAccionColor(a.accion), size: 20),
                        ),
                        title: Text(
                          a.descripcion ?? a.accion,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(a.usuarioNombre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const Spacer(),
                                Text(
                                  a.createdAt != null 
                                      ? DateFormat('dd/MM HH:mm').format(a.createdAt!.toLocal())
                                      : 'Hace poco',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getAccionIcon(String accion) {
    if (accion.contains('pago')) return Icons.payments_outlined;
    if (accion.contains('crear')) return Icons.add_circle_outline;
    if (accion.contains('editar')) return Icons.edit_outlined;
    if (accion.contains('borrar') || accion.contains('eliminar')) return Icons.delete_outline;
    if (accion.contains('compartir')) return Icons.share_outlined;
    return Icons.info_outline;
  }

  Color _getAccionColor(String accion) {
    if (accion.contains('pago')) return Colors.green;
    if (accion.contains('crear')) return Colors.blue;
    if (accion.contains('editar')) return Colors.orange;
    if (accion.contains('borrar') || accion.contains('eliminar')) return Colors.red;
    return Colors.grey;
  }
}
