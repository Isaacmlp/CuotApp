import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/utils/ahorro_logic_helper.dart';

class TarjetaGrupo extends StatelessWidget {
  final GrupoAhorro grupo;
  final List<MiembroGrupo>? miembros;
  final VoidCallback onVerDetalle;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const TarjetaGrupo({
    super.key,
    required this.grupo,
    required this.onVerDetalle,
    this.miembros,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // Buscar quién tiene este turno (para mostrar quién recibe)
    String nombreRecibe = 'Pendiente';
    if (miembros != null) {
      final m = miembros!.where((m) => m.numeroTurno == grupo.turnoActual).firstOrNull;
      if (m != null) nombreRecibe = m.nombreCliente ?? 'N/A';
    }

    final double progresoTurno = grupo.metaAhorro > 0 
        ? (grupo.recaudadoTurno / grupo.metaAhorro).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primaryGreen.withOpacity(0.03)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA: Nombre y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      grupo.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      grupo.estado.name.toUpperCase(),
                      style: const TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // INFO TURNOS Y FRECUENCIA
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frecuencia: ${grupo.periodo.name.toUpperCase()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              'A recibir: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            Text(
                              nombreRecibe,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.darkGrey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Turno #${grupo.turnoActual}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStat('En Caja', '\$${grupo.recaudadoTurno.toStringAsFixed(0)}', AppColors.primaryGreen),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // BARRA AL FONDO CON BOTÓN DE OJO (REQUERIMIENTO NUEVO)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 8,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progresoTurno,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.lightGreen]),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progresoTurno * 100).toStringAsFixed(0)}% de la meta por turno',
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // BOTÓN DEL OJITO (VER) AL FINAL A LA DERECHA
                  InkWell(
                    onTap: onVerDetalle,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
