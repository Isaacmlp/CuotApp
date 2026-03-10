import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/ui/pages/cuotapp_login_page.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String? nombre_usuario; // Callback para navegación segura

  const CustomDrawer({
    super.key,
    required this.nombre_usuario,
// Requerido para navegar
  });

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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.lightGreen,
                  ],
                ),
              ),
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.pureWhite,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nombre_usuario != null 
                          ? 'Hola, $nombre_usuario' 
                          : 'Hola, Usuario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ver perfil',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ), 
                  
            )
            ),

            
            
            // Items del menú
            _buildDrawerItem(
              
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () {
                Navigator.pop(context); // Solo cerrar drawer
              },
              isSelected: true,
            ),
            
             _buildDrawerItem(
              icon: Icons.credit_card,
              label: 'Financiar',
              
              onTap: () {
                // Usar el callback para navegar de forma segura
              Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreditoPage()),
            );
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.payment,
              label: 'Pagos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a pagos
                // onNavigate(PagosScreen());
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.calendar_today,
              label: 'Calendario de Pagos',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a calendario
                // onNavigate(CalendarioScreen());
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.history,
              label: 'Historial',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a historial
                // onNavigate(HistorialScreen());
              },
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
                // onNavigate(NotificacionesScreen());
              },
              showBadge: true,
              badgeCount: 3,
            ),
            
            _buildDrawerItem(
              icon: Icons.settings,
              label: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a configuración
                // onNavigate(ConfiguracionScreen());
              },
            ),
            
            _buildDrawerItem(
              icon: Icons.help_outline,
              label: 'Ayuda',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar navegación a ayuda
                // onNavigate(AyudaScreen());
              },
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
              onTap: () { Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => CuotAppLoginPage()),
              (Route<dynamic> route) => false);
              },
              color: AppColors.error,
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
    print("Fua los bugs");
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (isSelected ? AppColors.primaryGreen : AppColors.mediumGrey),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? (isSelected ? AppColors.primaryGreen : AppColors.darkGrey),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: showBadge
    ? Container(
        padding: const EdgeInsets.all(4), // El padding da el tamaño natural
        decoration: const BoxDecoration(
          color: Colors.red, // Usa AppColors.error
          shape: BoxShape.circle, // Círculo perfecto sin cálculos raros
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Text(
          badgeCount.toString(),
          textAlign: TextAlign.center, // Centrado de texto simple
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


  // Diálogo de cierre de sesión
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppColors.mediumGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Cerrar diálogo
                Navigator.pop(dialogContext);
                // Cerrar drawer
                Navigator.pop(context);
                // Navegar a login después de un delay
                Future.delayed(const Duration(milliseconds: 150), () {
                  // Usar el callback para navegar al login
                  // onNavigate(LoginScreen());
                  // Por ahora solo mostramos un mensaje
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesión cerrada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.pureWhite,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}