import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/user_admin_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/pages/admin/crear_usuario_page.dart';
import 'package:cuot_app/widget/admin/usuario_card.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';

class AdminUsuariosPage extends StatefulWidget {
  final String nombreUsuario;
  final String rol;
  final String correo;

  const AdminUsuariosPage({
    super.key,
    required this.nombreUsuario,
    required this.rol,
    required this.correo,
  });

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final UserAdminService _userService = UserAdminService();
  final BitacoraService _bitacoraService = BitacoraService();
  final TextEditingController _searchController = TextEditingController();

  List<Usuario> _usuarios = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtros
  String? _rolFilter;
  bool? _activoFilter;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarios = await _userService.getUsuarios(
        searchQuery: _searchController.text,
        rolFilter: _rolFilter,
        activoFilter: _activoFilter,
      );
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar usuarios: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editarRol(Usuario usuario) async {
    String? nuevoRol = await showDialog<String>(
      context: context,
      builder: (context) => _RolSelectorDialog(rolActual: usuario.rol),
    );

    if (nuevoRol != null && nuevoRol != usuario.rol) {
      try {
        await _userService.editarRol(usuario.id!, nuevoRol);
        await _bitacoraService.registrarActividad(
          usuarioNombre: widget.nombreUsuario,
          accion: 'editar_rol',
          descripcion: 'Cambió rol de ${usuario.nombreCompleto} de ${usuario.rol} a $nuevoRol',
          entidadId: usuario.id,
        );
        _showSnackBar('✅ Rol actualizado correctamente', Colors.green);
        _cargarUsuarios();
      } catch (e) {
        _showSnackBar('❌ Error al actualizar rol: $e', Colors.red);
      }
    }
  }

  Future<void> _toggleActivo(Usuario usuario) async {
    final nuevoEstado = !usuario.activo;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nuevoEstado ? '✅ Activar usuario' : '⛔ Desactivar usuario'),
        content: Text(
          nuevoEstado
              ? '¿Activar la cuenta de ${usuario.nombreCompleto}?'
              : '¿Desactivar la cuenta de ${usuario.nombreCompleto}?\nNo podrá iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado ? AppColors.primaryGreen : AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(nuevoEstado ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.toggleActivo(usuario.id!, nuevoEstado);
        await _bitacoraService.registrarActividad(
          usuarioNombre: widget.nombreUsuario,
          accion: 'toggle_activo',
          descripcion: '${nuevoEstado ? "Activó" : "Desactivó"} a ${usuario.nombreCompleto}',
          entidadId: usuario.id,
        );
        _showSnackBar(
          nuevoEstado ? '✅ Usuario activado' : '⛔ Usuario desactivado',
          nuevoEstado ? Colors.green : Colors.orange,
        );
        _cargarUsuarios();
      } catch (e) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  Future<void> _resetearContrasena(Usuario usuario) async {
    final TextEditingController passController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔑 Resetear contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nueva contraseña para ${usuario.nombreCompleto}:'),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirm == true && passController.text.isNotEmpty) {
      try {
        await _userService.resetearContrasena(
          usuario.correoElectronico,
          passController.text,
        );
        await _bitacoraService.registrarActividad(
          usuarioNombre: widget.nombreUsuario,
          accion: 'reset_contrasena',
          descripcion: 'Reseteó contraseña de ${usuario.nombreCompleto}',
          entidadId: usuario.id,
        );
        _showSnackBar('✅ Contraseña actualizada', Colors.green);
      } catch (e) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
    passController.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        nombre_usuario: widget.nombreUsuario,
        ventanaActiva: 'gestion_usuarios',
        rol: widget.rol,
        correo: widget.correo,
      ),
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _cargarUsuarios(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o email...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _cargarUsuarios();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtros de rol
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', _rolFilter == null && _activoFilter == null, () {
                        setState(() { _rolFilter = null; _activoFilter = null; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Admin', _rolFilter == 'admin', () {
                        setState(() { _rolFilter = _rolFilter == 'admin' ? null : 'admin'; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Supervisor', _rolFilter == 'supervisor', () {
                        setState(() { _rolFilter = _rolFilter == 'supervisor' ? null : 'supervisor'; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Empleado', _rolFilter == 'empleado', () {
                        setState(() { _rolFilter = _rolFilter == 'empleado' ? null : 'empleado'; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Cliente', _rolFilter == 'cliente', () {
                        setState(() { _rolFilter = _rolFilter == 'cliente' ? null : 'cliente'; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Activos', _activoFilter == true, () {
                        setState(() { _activoFilter = _activoFilter == true ? null : true; _rolFilter = null; });
                        _cargarUsuarios();
                      }),
                      const SizedBox(width: 6),
                      _buildFilterChip('Inactivos', _activoFilter == false, () {
                        setState(() { _activoFilter = _activoFilter == false ? null : false; _rolFilter = null; });
                        _cargarUsuarios();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarUsuarios,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _usuarios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron usuarios',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarUsuarios,
                            color: AppColors.primaryGreen,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _usuarios.length,
                              itemBuilder: (context, index) {
                                final usuario = _usuarios[index];
                                return UsuarioCard(
                                  usuario: usuario,
                                  onEditarRol: () => _editarRol(usuario),
                                  onToggleActivo: () => _toggleActivo(usuario),
                                  onResetearContrasena: () => _resetearContrasena(usuario),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CrearUsuarioPage(
                creadoPor: widget.nombreUsuario,
              ),
            ),
          );
          if (result == true) {
            _cargarUsuarios();
          }
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGreen : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// Diálogo selector de rol
class _RolSelectorDialog extends StatelessWidget {
  final String rolActual;

  const _RolSelectorDialog({required this.rolActual});

  @override
  Widget build(BuildContext context) {
    final roles = [
      {'value': 'admin', 'label': 'Administrador', 'icon': Icons.admin_panel_settings, 'color': Colors.blue},
      {'value': 'supervisor', 'label': 'Supervisor', 'icon': Icons.supervisor_account, 'color': Colors.orange},
      {'value': 'empleado', 'label': 'Empleado', 'icon': Icons.person, 'color': Colors.amber},
      {'value': 'cliente', 'label': 'Cliente', 'icon': Icons.person_outline, 'color': AppColors.primaryGreen},
    ];

    return AlertDialog(
      title: const Text('👤 Seleccionar Rol'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: roles.map((r) {
          final isSelected = r['value'] == rolActual;
          return ListTile(
            leading: Icon(r['icon'] as IconData, color: r['color'] as Color),
            title: Text(
              r['label'] as String,
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
            trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
            onTap: () => Navigator.pop(context, r['value'] as String),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isSelected ? AppColors.veryLightGreen : null,
          );
        }).toList(),
      ),
    );
  }
}
