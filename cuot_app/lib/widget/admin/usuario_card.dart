import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UsuarioCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onEditarRol;
  final VoidCallback onToggleActivo;
  final VoidCallback onResetearContrasena;
  final VoidCallback onAsignarCredito;
  final VoidCallback onEliminar; // 👈 NUEVO

  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onEditarRol,
    required this.onToggleActivo,
    required this.onResetearContrasena,
    required this.onAsignarCredito,
    required this.onEliminar, // 👈 NUEVO
  });

  Color _getRolColor() {
    switch (usuario.rol) {
      case 'admin':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'empleado':
        return Colors.amber.shade700;
      case 'cliente':
        return AppColors.primaryGreen;
      default:
        return AppColors.mediumGrey;
    }
  }

  IconData _getRolIcon() {
    switch (usuario.rol) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'empleado':
        return Icons.person;
      case 'cliente':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolColor = _getRolColor();
    final initial = usuario.nombreCompleto.isNotEmpty
        ? usuario.nombreCompleto[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: usuario.activo ? Colors.grey.shade200 : Colors.red.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar con inicial
                CircleAvatar(
                  radius: 24,
                  backgroundColor: usuario.activo
                      ? rolColor.withOpacity(0.15)
                      : Colors.grey.shade200,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: usuario.activo ? rolColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              usuario.nombreCompleto,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: usuario.activo ? AppColors.darkGrey : Colors.grey,
                                decoration: usuario.activo ? null : TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!usuario.activo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Inactivo',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario.correoElectronico,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badge de rol
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getRolIcon(), size: 14, color: rolColor),
                            const SizedBox(width: 4),
                            Text(
                              usuario.rolDisplayName,
                              style: TextStyle(
                                color: rolColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Menú de 3 puntos ────────────────────────────────────────
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    switch (value) {
                      case 'rol': onEditarRol(); break;
                      case 'activo': onToggleActivo(); break;
                      case 'pass': onResetearContrasena(); break;
                      case 'registros': onAsignarCredito(); break;
                      case 'eliminar': onEliminar(); break;
                    }
                  },
                  itemBuilder: (context) => [
                    _buildMenuItem('rol', 'Cambiar Rol', Icons.badge_outlined, Colors.blue),
                    _buildMenuItem(
                      'activo', 
                      usuario.activo ? 'Desactivar' : 'Activar', 
                      usuario.activo ? Icons.block : Icons.check_circle_outline, 
                      usuario.activo ? Colors.orange : AppColors.primaryGreen
                    ),
                    _buildMenuItem('pass', 'Contraseña', Icons.lock_reset, Colors.purple),
                    if (usuario.rol != 'cliente')
                      _buildMenuItem('registros', 'Registros', Icons.assignment_ind_outlined, AppColors.primaryGreen),
                    const PopupMenuDivider(),
                    _buildMenuItem('eliminar', 'Eliminar', Icons.delete_forever_outlined, AppColors.error),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
