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
  Map<String, String> _nombresClientes = {};
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

      // Obtener nombres de clientes para los créditos
      Map<String, String> nombres = {};
      for (var a in asignaciones) {
        if (!nombres.containsKey(a.creditoId)) {
          try {
            final creditData = await _creditService.getCreditById(a.creditoId);
            nombres[a.creditoId] = creditData?['Clientes']?['nombre'] ?? 'ID: ${a.creditoId}';
          } catch (_) {
            nombres[a.creditoId] = 'ID: ${a.creditoId}';
          }
        }
      }

      if (mounted) {
        setState(() {
          _asignaciones = asignaciones;
          _actividadesPorEmpleado = actividades;
          _nombresClientes = nombres;
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

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                child: Text(nombre[0].toUpperCase(), 
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              ),
              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${asignacionesEmp.length} crédito(s) asignado(s)'),
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Créditos Asignados', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen)),
                      const SizedBox(height: 8),
                      ...asignacionesEmp.map((a) => _buildAsignacionItem(a)),
                      const SizedBox(height: 16),
                      const Text('Actividad Reciente', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen)),
                      const SizedBox(height: 8),
                      if (actividades.isEmpty)
                        const Text('Sin actividad reciente', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else
                        ...actividades.map((act) => _buildBitacoraItem(act)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAsignacionItem(CreditoCompartido a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, size: 16, color: AppColors.darkGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombresClientes[a.creditoId] ?? 'Cargando...', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Permisos: ${a.permisos}', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
            onPressed: () => _revocarAcceso(a),
          ),
        ],
      ),
    );
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
