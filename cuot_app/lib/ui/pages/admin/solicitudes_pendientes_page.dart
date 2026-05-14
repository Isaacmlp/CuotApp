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
  List<Map<String, dynamic>> _aportesPendientes = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _savingsService.getAportesPendientes(widget.adminNombre),
      ]);

      if (mounted) {
        setState(() {
          _creditosPendientes = results[0];
          _gruposPendientes = results[1];
          _pagosPendientes = results[2];
          _renovacionesPendientes = results[3];
          _aportesPendientes = results[4];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando solicitudes pendientes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalPendientes =>
      _creditosPendientes.length +
      _gruposPendientes.length +
      _pagosPendientes.length +
      _renovacionesPendientes.length +
      _aportesPendientes.length;

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
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Registros (${_creditosPendientes.length})'),
            Tab(text: 'Grupos (${_gruposPendientes.length})'),
            Tab(text: 'Abonos (${_pagosPendientes.length})'),
            Tab(text: 'Renovaciones (${_renovacionesPendientes.length})'),
            Tab(text: 'Aportes (${_aportesPendientes.length})'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _totalPendientes == 0
          ? _buildEmptyState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_creditosPendientes, 'credito'),
                _buildList(_gruposPendientes, 'grupo'),
                _buildList(_pagosPendientes, 'pago'),
                _buildList(_renovacionesPendientes, 'renovacion'),
                _buildList(_aportesPendientes, 'aporte'),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 72, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Todo verificado!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay solicitudes pendientes de aprobación.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
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

    return RefreshIndicator(
      onRefresh: _loadAllPending,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildRequestCard(item, tipo);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item, String tipo) {
    String title = '';
    String subtitle = '';
    String extra = '';
    String? imageUrl;
    String? creador;

    if (tipo == 'credito') {
      final String tipoCred = item['tipo_credito'] == 'unico' ? 'Cuota Única' : 'Cuotas';
      title = 'Registro ($tipoCred): ${item['concepto']}';
      subtitle = 'Cliente: ${item['Clientes']?['nombre'] ?? 'N/A'}';
      final double total = ((item['costo_inversion'] ?? 0) as num).toDouble() + 
                           ((item['margen_ganancia'] ?? 0) as num).toDouble();
      extra = 'Monto Total: \$${total.toStringAsFixed(2)}';
      creador = item['creado_por'] ?? item['usuario_nombre'];
      
      // Detalles de cuotas
      final cuotas = item['Cuotas'] as List? ?? [];
      if (cuotas.isNotEmpty) {
        cuotas.sort((a, b) => (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));
        extra += '\n\nCALENDARIO DE PAGOS:';
        for (var c in cuotas) {
          final fecha = DateFormat('dd/MM/yyyy').format(DateTime.parse(c['fecha_pago']));
          final monto = ((c['monto'] ?? 0) as num).toStringAsFixed(2);
          extra += '\n• $fecha: \$$monto';
        }
      }
    } else if (tipo == 'grupo') {
      title = 'Grupo: ${item['nombre'] ?? item['nombre_grupo'] ?? 'Sin nombre'}';
      subtitle = 'Participantes: ${item['cantidad_participantes'] ?? 'N/A'}';
      extra = 'Meta: \$${((item['meta_ahorro'] ?? 0) as num).toStringAsFixed(2)}';
      creador = item['creado_por'];
    } else if (tipo == 'pago') {
      title = 'Abono: \$${((item['monto'] ?? 0) as num).toStringAsFixed(2)}';
      subtitle = 'Préstamo: ${item['Creditos']?['concepto'] ?? 'N/A'}';
      extra = 'Cliente: ${item['Creditos']?['Clientes']?['nombre'] ?? 'N/A'}';
      imageUrl = item['comprobante_path'];
      creador = item['creado_por'] ?? item['usuario_nombre'];
    } else if (tipo == 'renovacion') {
      title = 'Renovación';
      subtitle = 'Préstamo: ${item['Creditos']?['concepto'] ?? 'N/A'}';
      final condiciones = item['condiciones_nuevas'] ?? {};
      extra = 'Nuevo Total: \$${((condiciones['monto_total'] ?? 0) as num).toStringAsFixed(2)}';
      creador = item['creado_por'] ?? item['usuario_autoriza']; 
    } else if (tipo == 'aporte') {
      final double monto = ((item['monto'] ?? 0) as num).toDouble();
      title = 'Aporte: \$${monto.toStringAsFixed(2)}';
      final miembro = item['Miembros_Grupo'];
      subtitle = 'Miembro: ${miembro?['Clientes']?['nombre'] ?? 'N/A'}';
      extra = 'Método: ${item['metodo_pago'] ?? 'efectivo'}';
      creador = item['creado_por'] ?? (miembro?['Clientes']?['nombre']);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                if (creador != null && creador.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Creado por: $creador',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
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
                TextButton.icon(
                  onPressed: () => _rejectRequest(item, tipo),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveRequest(item, tipo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprobar'),
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
          final String? creadorNombre = item['usuario_nombre'];
          final bool? asignar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text('Aprobación Exitosa'),
                ],
              ),
              content: Text('El crédito ha sido aprobado y asignado a tu panel.\n\n¿Deseas asignárselo a ${creadorNombre ?? "el empleado"} para que lo gestione?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Más tarde')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true), 
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                  child: const Text('Asignar ahora'),
                ),
              ],
            ),
          );

          if (asignar == true && creadorNombre != null) {
            try {
              final userService = UserAdminService();
              final users = await userService.listarUsuarios();
              final creator = users.firstWhere(
                (u) => u.nombre == creadorNombre,
                orElse: () => Usuario(nombreCompleto: creadorNombre, correoElectronico: ''),
              );
              
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => AsignarCreditoDialog(
                    usuarioDestino: creator,
                    adminNombre: widget.adminNombre,
                  ),
                );
              }
            } catch (e) {
              print('Error al abrir diálogo de asignación: $e');
            }
          }
        }
      } else if (tipo == 'grupo') {
        await _savingsService.aprobarGrupo(id);
      } else if (tipo == 'pago') {
        await _creditService.aprobarPago(item);
      } else if (tipo == 'renovacion') {
        await _renovacionService.aprobarRenovacion(id);
      } else if (tipo == 'aporte') {
        await _savingsService.aprobarAporte(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Solicitud aprobada'), backgroundColor: Colors.green),
        );
      }
      _loadAllPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al aprobar: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> item, String tipo) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Rechazo'),
          ],
        ),
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
        await _creditService.deletePayment(id);
      } else if (tipo == 'renovacion') {
        await _renovacionService.actualizarEstado(
          renovacionId: id, 
          estadoAnterior: 'pendiente', 
          estadoNuevo: 'rechazada',
        );
      } else if (tipo == 'aporte') {
        // Para aportes rechazados, simplemente eliminamos el registro
        // ya que nunca afectó los saldos
        await _savingsService.deleteAporte(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚫 Solicitud rechazada'), backgroundColor: Colors.orange),
        );
      }
      _loadAllPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al rechazar: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
