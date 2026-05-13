import 'package:cuot_app/Model/bitacora_model.dart';
import 'package:cuot_app/Model/credito_compartido_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmpleadosPage extends StatefulWidget {
  final String adminNombre;
  final String rol;
  final String correo;

  const EmpleadosPage({
    super.key,
    required this.adminNombre,
    required this.rol,
    required this.correo,
  });

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final CreditoCompartidoService _compartidoService = CreditoCompartidoService();
  final BitacoraService _bitacoraService = BitacoraService();
  final CreditService _creditService = CreditService();

  List<CreditoCompartido> _asignaciones = [];
  Map<String, List<BitacoraActividad>> _actividadesPorEmpleado = {};
  Map<String, Map<String, dynamic>> _detallesCreditos = {}; // 👈 CAMBIADO: Guardar mapa completo de detalles
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final asignaciones = await _compartidoService
          .obtenerCreditosCompartidosPorPropietario(widget.adminNombre);
      
      Map<String, List<BitacoraActividad>> actividades = {};
      
      // Obtener nombres únicos de empleados
      final empleados = asignaciones.map((a) => a.trabajadorNombre).toSet();
      
      for (var emp in empleados) {
        try {
          final acts = await _bitacoraService.obtenerActividades(
            limit: 10,
            usuariosFilter: [emp],
          );
          actividades[emp] = acts;
        } catch (e) {
          // Ignorar silenciosamente si hay RLS o error al obtener actividades
          // de un empleado en particular para no romper toda la vista
          actividades[emp] = [];
        }
      }

      // Obtener detalles completos de los créditos
      Map<String, Map<String, dynamic>> detalles = {};
      for (var a in asignaciones) {
        if (!detalles.containsKey(a.creditoId)) {
          try {
            final creditData = await _creditService.getCreditById(a.creditoId);
            if (creditData != null) {
              detalles[a.creditoId] = creditData;
            }
          } catch (e) {
            print('Error cargando detalle de crédito ${a.creditoId}: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _asignaciones = asignaciones;
          _actividadesPorEmpleado = actividades;
          _detallesCreditos = detalles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar empleados: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _revocarAcceso(CreditoCompartido asignacion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar Acceso'),
        content: Text(
          '¿Estás seguro de revocar el acceso de ${asignacion.trabajadorNombre} a este crédito?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Revocar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _compartidoService.revocarAcceso(asignacion.id!);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso revocado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        nombre_usuario: widget.adminNombre,
        ventanaActiva: 'empleados',
        rol: widget.rol,
        correo: widget.correo,
      ),
      appBar: AppBar(
        title: const Text('Gestión de Empleados'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _asignaciones.isEmpty
                  ? const Center(child: Text('No tienes empleados con créditos asignados'))
                  : _buildListaEmpleados(),
    );
  }

  Widget _buildListaEmpleados() {
    final empleadosMap = <String, List<CreditoCompartido>>{};
    for (var a in _asignaciones) {
      empleadosMap.putIfAbsent(a.trabajadorNombre, () => []).add(a);
    }

    final empleados = empleadosMap.keys.toList();

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: empleados.length,
        itemBuilder: (context, index) {
          final nombre = empleados[index];
          final asignacionesEmp = empleadosMap[nombre]!;
          final actividades = _actividadesPorEmpleado[nombre] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen.withOpacity(0.1), AppColors.lightGreen.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nombre[0].toUpperCase(), 
                      style: const TextStyle(
                        color: AppColors.primaryGreen, 
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  nombre, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkGrey,
                  ),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.assignment_ind_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${asignacionesEmp.length} registro(s) asignado(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                children: [
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card_outlined, size: 16, color: AppColors.primaryGreen.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            const Text(
                              'Registros Asignados', 
                              style: TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 13, 
                                color: AppColors.primaryGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...asignacionesEmp.map((a) => _buildAsignacionItem(a)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.history_toggle_off, size: 16, color: AppColors.primaryGreen.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            const Text(
                              'Actividad Reciente', 
                              style: TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 13, 
                                color: AppColors.primaryGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (actividades.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Sin actividad reciente', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          )
                        else
                          ...actividades.map((act) => _buildBitacoraItem(act)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAsignacionItem(CreditoCompartido a) {
    final detalle = _detallesCreditos[a.creditoId];
    final String cliente = detalle?['Clientes']?['nombre'] ?? 'Desconocido';
    final String concepto = detalle?['concepto'] ?? 'Sin concepto';
    final String numReg = detalle?['numero_credito']?.toString() ?? '--';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral de color según permisos
              Container(
                width: 6,
                color: _getPermisoColor(a.permisos),
              ),
              const SizedBox(width: 12),
              
              // Información Principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Reg #$numReg',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            a.permisos.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _getPermisoColor(a.permisos),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cliente,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      Text(
                        concepto,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Acciones
              Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade50)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                  onPressed: () => _revocarAcceso(a),
                  tooltip: 'Revocar Acceso',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPermisoColor(String permisos) {
    switch (permisos.toLowerCase()) {
      case 'total':
        return Colors.blue.shade700;
      case 'cobro':
        return Colors.orange.shade700;
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _buildBitacoraItem(BitacoraActividad act) {
    final fecha = act.createdAt != null 
        ? DateFormat('dd/MM HH:mm').format(act.createdAt!) 
        : '--/--';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fecha, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${act.accionDisplayName}: ${act.descripcion ?? ""}',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
