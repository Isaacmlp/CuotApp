import 'package:flutter/material.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/service/renovacion_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cuot_app/widget/admin/asignar_credito_dialog.dart';
import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/service/user_admin_service.dart';

class SolicitudesPendientesPage extends StatefulWidget {
  final String adminNombre;

  const SolicitudesPendientesPage({super.key, required this.adminNombre});

  @override
  State<SolicitudesPendientesPage> createState() => _SolicitudesPendientesPageState();
}

class _SolicitudesPendientesPageState extends State<SolicitudesPendientesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreditService _creditService = CreditService();
  final SavingsService _savingsService = SavingsService();
  final RenovacionService _renovacionService = RenovacionService();

  List<Map<String, dynamic>> _creditosPendientes = [];
  List<Map<String, dynamic>> _gruposPendientes = [];
  List<Map<String, dynamic>> _pagosPendientes = [];
  List<Map<String, dynamic>> _renovacionesPendientes = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllPending();
  }

  Future<void> _loadAllPending() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _creditService.getCreditosPendientes(widget.adminNombre),
        _savingsService.getGruposPendientes(widget.adminNombre),
        _creditService.getPagosPendientes(widget.adminNombre),
        _renovacionService.getRenovacionesPendientes(widget.adminNombre),
      ]);

      if (mounted) {
        setState(() {
          _creditosPendientes = results[0];
          _gruposPendientes = results[1];
          _pagosPendientes = results[2];
          _renovacionesPendientes = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando solicitudes pendientes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes Pendientes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Créditos (${_creditosPendientes.length})'),
            Tab(text: 'Grupos (${_gruposPendientes.length})'),
            Tab(text: 'Abonos (${_pagosPendientes.length})'),
            Tab(text: 'Renovaciones (${_renovacionesPendientes.length})'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_creditosPendientes, 'credito'),
              _buildList(_gruposPendientes, 'grupo'),
              _buildList(_pagosPendientes, 'pago'),
              _buildList(_renovacionesPendientes, 'renovacion'),
            ],
          ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String tipo) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No hay solicitudes pendientes', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRequestCard(item, tipo);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item, String tipo) {
    String title = '';
    String subtitle = '';
    String extra = '';
    String? imageUrl;

    if (tipo == 'credito') {
      title = 'Crédito: ${item['concepto']}';
      subtitle = 'Cliente: ${item['Clientes']?['nombre'] ?? 'N/A'}';
      extra = 'Monto: \$${(item['costo_inversion'] + item['margen_ganancia']).toStringAsFixed(2)}';
    } else if (tipo == 'grupo') {
      title = 'Grupo: ${item['nombre_grupo']}';
      subtitle = 'Creado por: ${item['creado_por']}';
      extra = 'Monto: \$${(item['monto_total_grupo'] ?? 0).toStringAsFixed(2)}';
    } else if (tipo == 'pago') {
      title = 'Abono: \$${(item['monto'] ?? 0).toStringAsFixed(2)}';
      subtitle = 'Préstamo: ${item['Creditos']?['concepto'] ?? 'N/A'}';
      extra = 'Cliente: ${item['Creditos']?['Clientes']?['nombre'] ?? 'N/A'}';
      imageUrl = item['comprobante_path'];
    } else if (tipo == 'renovacion') {
      title = 'Renovación';
      subtitle = 'Préstamo: ${item['Creditos']?['concepto'] ?? 'N/A'}';
      final condiciones = item['condiciones_nuevas'] ?? {};
      extra = 'Nuevo Total: \$${(condiciones['monto_total'] ?? 0).toStringAsFixed(2)}';
    }

    return Card(
      margin: const EdgeInsets.bottom(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(subtitle),
                Text(extra, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showFullImage(imageUrl!),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.startsWith('http') 
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectRequest(item, tipo),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _approveRequest(item, tipo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(Map<String, dynamic> item, String tipo) async {
    final String id = item['id'].toString();
    setState(() => _isLoading = true);

    try {
      if (tipo == 'credito') {
        await _creditService.aprobarCredito(id);
        
        // Preguntar si desea asignar al creador
        if (mounted) {
          final bool? asignar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Aprobación Exitosa'),
              content: Text('El crédito ha sido aprobado.\n\n¿Deseas asignárselo a ${item['usuario_nombre']} ahora mismo?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Más tarde')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Asignar ahora')),
              ],
            ),
          );

          if (asignar == true) {
            // Abrir diálogo de asignación directamente
            final userService = UserAdminService();
            final users = await userService.listarUsuarios();
            final creator = users.firstWhere((u) => u.nombre == item['usuario_nombre']);
            
            if (mounted) {
              await showDialog(
                context: context,
                builder: (ctx) => AsignarCreditoDialog(
                  usuario: creator,
                  adminNombre: widget.adminNombre,
                  creditoPreseleccionadoId: id,
                ),
              );
            }
          }
        }
      } else if (tipo == 'grupo') {
        await _savingsService.aprobarGrupo(id);
      } else if (tipo == 'pago') {
        await _creditService.aprobarPago(item);
      } else if (tipo == 'renovacion') {
        await _renovacionService.aprobarRenovacion(id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Solicitud aprobada'), backgroundColor: Colors.green),
      );
      _loadAllPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al aprobar: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> item, String tipo) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Rechazo'),
        content: const Text('¿Estás seguro de que deseas rechazar esta solicitud? El registro será eliminado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final String id = item['id'].toString();
      if (tipo == 'credito') {
        await _creditService.deleteCredit(id);
      } else if (tipo == 'grupo') {
        await _savingsService.deleteGrupo(id);
      } else if (tipo == 'pago') {
        // En pagos, podríamos simplemente marcar como rechazado o borrar
        await _creditService.deletePayment(id);
      } else if (tipo == 'renovacion') {
        // Borrar la renovación pendiente
        // (Podríamos agregar un deleteRenovacion en el servicio si no existe)
        await _renovacionService.actualizarEstado(
          renovacionId: id, 
          estadoAnterior: 'pendiente', 
          estadoNuevo: 'rechazada',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 Solicitud rechazada'), backgroundColor: Colors.orange),
      );
      _loadAllPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al rechazar: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }
}
