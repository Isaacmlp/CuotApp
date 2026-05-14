import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/service/user_admin_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/pages/admin/crear_usuario_page.dart';
import 'package:cuot_app/widget/admin/asignar_credito_dialog.dart';
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
  final CreditoCompartidoService _compartidoService = CreditoCompartidoService();
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
        // Eliminamos el filtrado por creador para que todos vean a todos inicialmente
      );

      // Obtener todas las asignaciones para filtrar visibilidad exclusiva
      final asignaciones = await _compartidoService.obtenerTodosLosCreditosCompartidos();

      if (mounted) {
        setState(() {
          _usuarios = usuarios.where((u) {
            // 1. No mostrarse a sí mismo
            if (u.correoElectronico == widget.correo) return false;

            // 2. Buscar si el usuario tiene algún crédito asignado
            final tieneAsignacion = asignaciones.any((a) => a.trabajadorNombre.trim() == u.nombreCompleto.trim());

            if (tieneAsignacion) {
              // 3. Si tiene asignación, solo mostrar si yo soy EL propietario (o uno de ellos)
              final soyPropietario = asignaciones.any((a) => 
                a.trabajadorNombre.trim() == u.nombreCompleto.trim() && 
                a.propietarioNombre.trim() == widget.nombreUsuario.trim()
              );
              return soyPropietario;
            }

            // 4. Si no tiene asignaciones, es visible para todos los admins
            return true;
          }).toList();
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
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConfigurarUsuarioDialog(
        usuario: usuario,
        adminNombre: widget.nombreUsuario,
        onComplete: (role, types) {
          _cargarUsuarios();
          _showSnackBar('✅ Configuración actualizada', Colors.green);
          
          // Preguntar por asignación inmediata si el rol lo permite
          if (role == 'empleado' || role == 'supervisor') {
            _preguntarAsignacionInmediata(
              usuario.copyWith(
                rol: role,
                configAsignacion: {'tipos': types},
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _preguntarAsignacionInmediata(Usuario usuarioConfigurado) async {
    final bool? assignNow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 ¿Asignar Registros?'),
        content: Text('Has configurado a ${usuarioConfigurado.nombreCompleto}. ¿Deseas asignarle registros específicos ahora mismo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Más tarde')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Asignar ahora'),
          ),
        ],
      ),
    );

    if (assignNow == true && mounted) {
      showDialog(
        context: context,
        builder: (context) => AsignarCreditoDialog(
          adminNombre: widget.nombreUsuario,
          usuarioDestino: usuarioConfigurado,
        ),
      );
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
  
  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Usuario'),
        content: Text(
          '¿Estás seguro de eliminar permanentemente a ${usuario.nombreCompleto}?\n\nEsta acción no se puede deshacer.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.eliminarUsuario(usuario.id!);
        await _bitacoraService.registrarActividad(
          usuarioNombre: widget.nombreUsuario,
          accion: 'eliminar_usuario',
          descripcion: 'Eliminó permanentemente al usuario ${usuario.nombreCompleto}',
          entidadId: usuario.id,
        );
        _showSnackBar('✅ Usuario eliminado correctamente', Colors.green);
        _cargarUsuarios();
      } catch (e) {
        _showSnackBar('❌ Error al eliminar usuario: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _asignarCredito(Usuario usuario) async {
    await showDialog(
      context: context,
      builder: (context) => AsignarCreditoDialog(
        adminNombre: widget.nombreUsuario,
        usuarioDestino: usuario,
      ),
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
                                  onAsignarCredito: () => _asignarCredito(usuario),
                                  onEliminar: () => _eliminarUsuario(usuario),
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
            _showSnackBar('✅ Usuario creado correctamente', Colors.green);
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

// ── DIÁLOGO DE CONFIGURACIÓN EN 3 PASOS ────────────────────────────────────
class _ConfigurarUsuarioDialog extends StatefulWidget {
  final Usuario usuario;
  final String adminNombre;
  final Function(String role, List<String> types) onComplete;

  const _ConfigurarUsuarioDialog({
    required this.usuario,
    required this.adminNombre,
    required this.onComplete,
  });

  @override
  State<_ConfigurarUsuarioDialog> createState() => _ConfigurarUsuarioDialogState();
}

class _ConfigurarUsuarioDialogState extends State<_ConfigurarUsuarioDialog> {
  final UserAdminService _userService = UserAdminService();
  
  int _currentStep = 0;
  String _selectedRol = '';
  
  // Preferencias de tipos
  bool _prefSimples = true;
  bool _prefFijas = true;
  bool _prefGrupos = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRol = widget.usuario.rol;
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final dynamic config = widget.usuario.configAsignacion?['tipos'];
    if (config is List && config.isNotEmpty && mounted) {
      final List<String> prefs = List<String>.from(config);
      setState(() {
        _prefSimples = prefs.contains('simple');
        _prefFijas = prefs.contains('fija');
        _prefGrupos = prefs.contains('grupo');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.settings_suggest_outlined, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  const Text('Configurar Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            
            Stepper(
              physics: const NeverScrollableScrollPhysics(),
              currentStep: _currentStep,
              onStepContinue: _nextStep,
              onStepCancel: _prevStep,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Atrás'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == 2 ? 'Finalizar' : 'Siguiente'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Rol'),
                  subtitle: Text('Actual: ${_selectedRol.toUpperCase()}'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.editing,
                  content: _buildRoleStep(),
                ),
                Step(
                  title: const Text('Tipos de Registros'),
                  subtitle: const Text('Permitidos para trabajar'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.editing,
                  content: _buildTypesStep(),
                ),
                Step(
                  title: const Text('Asignación'),
                  subtitle: const Text('Confirmar cambios'),
                  isActive: _currentStep >= 2,
                  state: StepState.editing,
                  content: _buildFinalStep(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    final roles = [
      {'val': 'admin', 'lab': 'Administrador', 'ico': Icons.admin_panel_settings, 'col': Colors.blue},
      {'val': 'supervisor', 'lab': 'Supervisor', 'ico': Icons.supervisor_account, 'col': Colors.orange},
      {'val': 'empleado', 'lab': 'Empleado', 'ico': Icons.person, 'col': Colors.amber},
      {'val': 'cliente', 'lab': 'Cliente', 'ico': Icons.person_outline, 'col': AppColors.primaryGreen},
    ];

    return Column(
      children: roles.map((r) => RadioListTile<String>(
        title: Text(r['lab'] as String),
        secondary: Icon(r['ico'] as IconData, color: r['col'] as Color),
        value: r['val'] as String,
        groupValue: _selectedRol,
        onChanged: (v) => setState(() => _selectedRol = v!),
        activeColor: AppColors.primaryGreen,
      )).toList(),
    );
  }

  Widget _buildTypesStep() {
    if (_selectedRol == 'cliente' || _selectedRol == 'admin') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Este rol no requiere configuración de tipos de trabajo.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Cuotas Simples'),
          subtitle: const Text('Préstamos de un solo pago'),
          value: _prefSimples,
          onChanged: (v) => setState(() => _prefSimples = v!),
          activeColor: AppColors.primaryGreen,
        ),
        CheckboxListTile(
          title: const Text('Cuotas Fijas'),
          subtitle: const Text('Financiamientos recurrentes'),
          value: _prefFijas,
          onChanged: (v) => setState(() => _prefFijas = v!),
          activeColor: AppColors.primaryGreen,
        ),
        CheckboxListTile(
          title: const Text('Grupos de Ahorro'),
          subtitle: const Text('Susu / Ahorros grupales'),
          value: _prefGrupos,
          onChanged: (v) => setState(() => _prefGrupos = v!),
          activeColor: AppColors.primaryGreen,
        ),
      ],
    );
  }

  Widget _buildFinalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Se aplicarán los siguientes cambios:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSummaryItem(Icons.badge, 'Rol', _selectedRol.toUpperCase()),
        if (_selectedRol == 'empleado' || _selectedRol == 'supervisor') ...[
          _buildSummaryItem(Icons.check_box, 'Tipos permitidos', 
            [if(_prefSimples) 'Simples', if(_prefFijas) 'Fijas', if(_prefGrupos) 'Grupos'].join(', ')),
        ],
        const SizedBox(height: 16),
        const Text('Al finalizar se actualizará el usuario en la nube.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    // FINALIZAR
    setState(() => _isLoading = true);
    try {
      // Preparar configuración de tipos
      Map<String, dynamic>? configAsignacion;
      if (_selectedRol == 'empleado' || _selectedRol == 'supervisor') {
        final List<String> tipos = [];
        if (_prefSimples) tipos.add('simple');
        if (_prefFijas) tipos.add('fija');
        if (_prefGrupos) tipos.add('grupo');
        configAsignacion = {'tipos': tipos};
      }

      // Guardar Rol y Configuración en un solo paso
      await _userService.editarRol(
        widget.usuario.id!, 
        _selectedRol, 
        configAsignacion: configAsignacion
      );

      // Registrar Actividad
      if (_selectedRol != widget.usuario.rol) {
        await BitacoraService().registrarActividad(
          usuarioNombre: widget.adminNombre,
          accion: 'editar_rol',
          descripcion: 'Cambió rol de ${widget.usuario.nombreCompleto} a $_selectedRol',
          entidadId: widget.usuario.id,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        
        final List<String> tipos = [];
        if (_prefSimples) tipos.add('simple');
        if (_prefFijas) tipos.add('fija');
        if (_prefGrupos) tipos.add('grupo');
        
        widget.onComplete(_selectedRol, tipos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
