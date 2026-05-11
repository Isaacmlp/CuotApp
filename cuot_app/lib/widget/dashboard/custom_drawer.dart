import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/ui/pages/admin/admin_usuarios_page.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';
import 'package:cuot_app/ui/pages/historial_renovaciones_page.dart';
import 'package:cuot_app/ui/pages/seguimiento_creditos_page.dart';
import 'package:cuot_app/ui/pages/settings_screen.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  final String nombre_usuario;
  final String ventanaActiva;
  final String rol;
  final String correo;

  const CustomDrawer({
    super.key,
    required this.nombre_usuario,
    required this.ventanaActiva,
    this.rol = 'cliente',
    this.correo = '',
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _tieneCreditosAsignados = false;
  bool _checkingAsignados = true;

  @override
  void initState() {
    super.initState();
    _verificarCreditosAsignados();
  }

  Future<void> _verificarCreditosAsignados() async {
    try {
      final tiene = await CreditoCompartidoService()
          .tieneCreditosAsignados(widget.nombre_usuario);
      if (mounted) {
        setState(() {
          _tieneCreditosAsignados = tiene;
          _checkingAsignados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingAsignados = false;
        });
      }
    }
  }

  String _getRolBadge() {
    switch (widget.rol) {
      case 'admin':
        return '🔰 Administrador';
      case 'supervisor':
        return '👔 Supervisor';
      case 'empleado':
        return '👷 Empleado';
      case 'cliente':
        return '👤 Cliente';
      default:
        return '👤 Usuario';
    }
  }

  Color _getRolColor() {
    switch (widget.rol) {
      case 'admin':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'empleado':
        return Colors.amber;
      case 'cliente':
        return AppColors.primaryGreen;
      default:
        return AppColors.mediumGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.pureWhite,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del Drawer con gradiente verde
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.lightGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.pureWhite,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.nombre_usuario.isNotEmpty
                        ? 'Hola, ${widget.nombre_usuario.split(' ').first}'
                        : 'Hola, Usuario',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Badge de rol
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRolBadge(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Items del menú con detección de ventana activa
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Menu Principal',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      correo: widget.correo,
                      userName: widget.nombre_usuario,
                      rol: widget.rol,
                    ),
                  ),
                );
              },
              isSelected: widget.ventanaActiva == 'dashboard',
            ),

            _buildDrawerItem(
              icon: Icons.credit_card,
              label: 'Cuotas Personales',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeguimientoCreditosPage(
                      nombreUsuario: widget.nombre_usuario,
                      rol: widget.rol,
                      correo: widget.correo,
                    ),
                  ),
                );
              },
              isSelected: widget.ventanaActiva == 'Cuotas Personales',
            ),

            // Opción "Trabajador" — solo visible si tiene créditos asignados
            if (!_checkingAsignados && _tieneCreditosAsignados)
              _buildDrawerItem(
                icon: Icons.work_outline,
                label: 'Trabajador',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeguimientoCreditosPage(
                        nombreUsuario: widget.nombre_usuario,
                        modoTrabajador: true,
                        rol: widget.rol,
                        correo: widget.correo,
                      ),
                    ),
                  );
                },
                isSelected: widget.ventanaActiva == 'trabajador',
              ),

            _buildDrawerItem(
              icon: Icons.history,
              label: 'Historial',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialRenovacionesPage(
                      nombreUsuario: widget.nombre_usuario,
                    ),
                  ),
                );
              },
              isSelected: widget.ventanaActiva == 'historial',
            ),

            const Divider(
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildDrawerItem(
              icon: Icons.notifications_outlined,
              label: 'Notificaciones',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a notificaciones
              },
              showBadge: true,
              badgeCount: 3,
              isSelected: widget.ventanaActiva == 'notificaciones',
            ),

            // Gestión de Usuarios — solo para admin
            if (widget.rol == 'admin')
              _buildDrawerItem(
                icon: Icons.admin_panel_settings,
                label: 'Gestión de Usuarios',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUsuariosPage(
                        nombreUsuario: widget.nombre_usuario,
                        rol: widget.rol,
                        correo: widget.correo,
                      ),
                    ),
                  );
                },
                isSelected: widget.ventanaActiva == 'gestion_usuarios',
              ),

            _buildDrawerItem(
              icon: Icons.settings,
              label: 'Configuración',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      nombreUsuario: widget.nombre_usuario,
                    ),
                  ),
                );
              },
              isSelected: widget.ventanaActiva == 'Configuración',
            ),

            _buildDrawerItem(
              icon: Icons.help_outline,
              label: 'Ayuda',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a ayuda
              },
              isSelected: widget.ventanaActiva == 'ayuda',
            ),

            const Divider(
              height: 32,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildDrawerItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => CuotAppLoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              color: AppColors.error,
              isSelected: false,
            ),

            const SizedBox(height: 20),

            // Versión de la app
            Center(
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  color: AppColors.mediumGrey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir items del drawer
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isSelected = false,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ??
            (isSelected ? AppColors.primaryGreen : AppColors.mediumGrey),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ??
              (isSelected ? AppColors.primaryGreen : AppColors.darkGrey),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: showBadge
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}
