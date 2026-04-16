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
    final double progreso = grupo.metaAhorro > 0 
        ? (grupo.totalAcumulado / grupo.metaAhorro).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.primaryGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grupo.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Frecuencia: ${grupo.periodo.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      grupo.estado.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('En Caja', '\$${grupo.totalAcumulado.toStringAsFixed(2)}', AppColors.primaryGreen),
                  _buildStat('Total', '\$${grupo.metaAhorro.toStringAsFixed(2)}', AppColors.darkGrey),
                ],
              ),
              const SizedBox(height: 24),
              // Barra de progreso interactiva (REQUERIMIENTO 6 + NUEVO: DINÁMICA)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   LayoutBuilder(
                    builder: (context, constraints) {
                      final double leftOffset = (constraints.maxWidth * progreso) - 20;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // La Barra
                          Container(
                            height: 10,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progreso,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primaryGreen, AppColors.lightGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // El Indicador Móvil (Recaudado)
                          if (progreso > 0.05)
                            Positioned(
                              left: leftOffset < 0 ? 0 : (leftOffset > constraints.maxWidth - 60 ? constraints.maxWidth - 60 : leftOffset),
                              top: -22,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '\$${grupo.totalAcumulado.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progreso * 100).toStringAsFixed(1)}% completado',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Faltan: \$${(grupo.metaAhorro - grupo.totalAcumulado).clamp(0, double.infinity).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: AppColors.error.withOpacity(0.7), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEliminar != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      onPressed: onEliminar,
                    ),
                  if (onEditar != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.mediumGrey, size: 20),
                      onPressed: onEditar,
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onVerDetalle,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver'), // REQUERIMIENTO 5
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info.withOpacity(0.1),
                      foregroundColor: AppColors.info,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
