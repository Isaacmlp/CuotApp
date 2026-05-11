import 'package:cuot_app/Model/bitacora_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivityWidget extends StatefulWidget {
  final String userName;
  final String rol;

  const RecentActivityWidget({super.key, required this.userName, required this.rol});

  @override
  State<RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<RecentActivityWidget> {
  final BitacoraService _bitacoraService = BitacoraService();
  List<BitacoraActividad> _actividades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    // Si es admin, ve global. Si no, solo lo suyo
    final acts = await _bitacoraService.obtenerActividades(
      limit: 10,
      usuarioFilter: widget.rol == 'admin' ? null : widget.userName,
    );
    if (mounted) {
      setState(() {
        _actividades = acts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_actividades.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Actividad Reciente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actividades.length,
          itemBuilder: (context, index) {
            final a = _actividades[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getAccionColor(a.accion).withOpacity(0.1),
                    radius: 18,
                    child: Icon(_getAccionIcon(a.accion), color: _getAccionColor(a.accion), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.descripcion ?? a.accionDisplayName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a.usuarioNombre,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              a.createdAt != null 
                                ? DateFormat('HH:mm').format(a.createdAt!)
                                : '-',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  IconData _getAccionIcon(String accion) {
     if (accion.contains('pago')) return Icons.payments_outlined;
    if (accion.contains('crear')) return Icons.add_circle_outline;
    if (accion.contains('editar')) return Icons.edit_outlined;
    if (accion.contains('renovacion')) return Icons.refresh;
    return Icons.info_outline;
  }

  Color _getAccionColor(String accion) {
    if (accion.contains('pago')) return Colors.green;
    if (accion.contains('crear')) return Colors.blue;
    if (accion.contains('editar')) return Colors.orange;
    if (accion.contains('renovacion')) return Colors.purple;
    return Colors.grey;
  }
}
