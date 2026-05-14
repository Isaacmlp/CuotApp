import 'dart:io';

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
  State<SolicitudesPendientesPage> createState() =>
      _SolicitudesPendientesPageState();
}

class _SolicitudesPendientesPageState extends State<SolicitudesPendientesPage>
    with SingleTickerProviderStateMixin {
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
            child: const Icon(Icons.check_circle_outline,
                size: 72, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Todo verificado!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey),
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
            Text('No hay solicitudes pendientes',
                style: TextStyle(color: Colors.grey[500])),
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
    switch (tipo) {
      case 'credito':
        return _buildCreditRequestCard(item);
      case 'grupo':
        return _buildGroupRequestCard(item);
      case 'pago':
        return _buildPaymentRequestCard(item);
      case 'renovacion':
        return _buildRenovationRequestCard(item);
      case 'aporte':
        return _buildContributionRequestCard(item);
      default:
        return _buildGenericRequestCard(item, tipo);
    }
  }

  Widget _buildGenericRequestCard(Map<String, dynamic> item, String tipo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        title: Text('Solicitud: $tipo'),
        subtitle: Text('ID: ${item['id']}'),
        trailing: _buildActionButtons(item, tipo),
      ),
    );
  }

  Widget _buildGroupRequestCard(Map<String, dynamic> item) {
    final String nombre =
        item['nombre'] ?? item['nombre_grupo'] ?? 'Sin nombre';
    final int participantes = item['cantidad_participantes'] ?? 0;
    final double meta = ((item['meta_ahorro'] ?? 0) as num).toDouble();
    final String creador = item['creado_por'] ?? 'Sistema';
    final String descripcion = item['descripcion'] ?? 'Sin descripción';

    return _buildPremiumCard(
      tipo: 'grupo',
      item: item,
      title: 'Nuevo Grupo: $nombre',
      tag: 'Grupo de Ahorro',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfoItem('Participantes', '$participantes', Icons.group),
              _buildInfoItem(
                  'Recaudación', '\$${meta.toStringAsFixed(2)}', Icons.flag),
              _buildInfoItem(
                  'Frecuencia',
                  (item['periodo'] ?? 'semanal').toString().toUpperCase(),
                  Icons.timer),
            ],
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoteSection(descripcion),
          ],
        ],
      ),
      creador: creador,
    );
  }

  Widget _buildPaymentRequestCard(Map<String, dynamic> item) {
    final double monto = ((item['monto'] ?? 0) as num).toDouble();
    final double? montoBs = item['monto_bs'] != null
        ? ((item['monto_bs']) as num).toDouble()
        : null;
    final double? montoUsd = item['monto_usd'] != null
        ? ((item['monto_usd']) as num).toDouble()
        : null;

    final String concepto = item['Creditos']?['concepto'] ?? 'N/A';
    final String cliente = item['Creditos']?['Clientes']?['nombre'] ?? 'N/A';
    final String ref = item['referencia'] ?? 'N/A';
    final String fecha = item['fecha_pago_real'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(item['fecha_pago_real']))
        : 'N/A';
    final String? captureUrl = item['comprobante_path'];
    final String creador =
        item['creado_por'] ?? item['usuario_nombre'] ?? 'Empleado';
    final String notas = item['observaciones'] ?? '';

    return _buildPremiumCard(
      tipo: 'pago',
      item: item,
      title: 'Abono Recibido: \$${monto.toStringAsFixed(2)}',
      tag: 'Verificación de Pago',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.person, 'Cliente: $cliente'),
          _buildDetailRow(Icons.description, 'Préstamo: $concepto'),
          const Divider(height: 24),
          Row(
            children: [
              _buildInfoItem('Fecha', fecha, Icons.calendar_today),
              _buildInfoItem('Referencia', ref, Icons.receipt_long),
              _buildInfoItem(
                  'Método',
                  (item['metodo_pago'] ?? 'Efectivo').toString().toUpperCase(),
                  Icons.payment),
            ],
          ),
          if (montoBs != null || montoUsd != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (montoBs != null)
                  _buildInfoItem('Monto Bs', 'Bs ${montoBs.toStringAsFixed(2)}',
                      Icons.account_balance),
                if (montoUsd != null)
                  _buildInfoItem(
                      'Monto USD',
                      '\$ ${montoUsd.toStringAsFixed(2)}',
                      Icons.monetization_on),
              ],
            ),
          ],
          if (notas.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoteSection(notas),
          ],
          if (captureUrl != null && captureUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('COMPROBANTE / CAPTURE:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullImage(captureUrl),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 10)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: (captureUrl != null && captureUrl.startsWith('http'))
                      ? Image.network(
                          captureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Error al cargar comprobante',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      : (captureUrl != null && captureUrl.isNotEmpty && File(captureUrl).existsSync())
                          ? Image.file(
                              File(captureUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Imagen local no disponible',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Sin imagen o no disponible',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                ),
              ),
            ),
          ],
        ],
      ),
      creador: creador,
    );
  }

  Widget _buildRenovationRequestCard(Map<String, dynamic> item) {
    final String concepto = item['Creditos']?['concepto'] ?? 'N/A';
    final String cliente = item['Creditos']?['Clientes']?['nombre'] ?? 'N/A';
    final condiciones = item['condiciones_nuevas'] ?? {};
    final double nuevoMonto =
        ((condiciones['monto_total'] ?? 0) as num).toDouble();
    final String creador =
        item['creado_por'] ?? item['usuario_autoriza'] ?? 'Sistema';

    return _buildPremiumCard(
      tipo: 'renovacion',
      item: item,
      title: 'Solicitud de Renovación',
      tag: 'Renovación',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.person, 'Cliente: $cliente'),
          _buildDetailRow(Icons.history, 'Préstamo Actual: $concepto'),
          const Divider(height: 24),
          Row(
            children: [
              _buildInfoItem('Nuevo Total',
                  '\$${nuevoMonto.toStringAsFixed(2)}', Icons.monetization_on),
              _buildInfoItem('Cuotas', '${condiciones['numero_cuotas'] ?? 0}',
                  Icons.repeat),
              _buildInfoItem(
                  'Modalidad',
                  (condiciones['modalidad_pago_nombre'] ?? 'N/A'),
                  Icons.schedule),
            ],
          ),
        ],
      ),
      creador: creador,
    );
  }

  Widget _buildContributionRequestCard(Map<String, dynamic> item) {
    final double monto = ((item['monto'] ?? 0) as num).toDouble();
    final miembro = item['Miembros_Grupo'];
    final String cliente = miembro?['Clientes']?['nombre'] ?? 'N/A';
    final String grupo = item['Grupos_Ahorro']?['nombre'] ?? 'N/A';
    final String creador = item['creado_por'] ?? cliente;

    return _buildPremiumCard(
      tipo: 'aporte',
      item: item,
      title: 'Aporte al Grupo: \$${monto.toStringAsFixed(2)}',
      tag: 'Aporte / Susu',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.person, 'Miembro: $cliente'),
          _buildDetailRow(Icons.group, 'Grupo: $grupo'),
          const Divider(height: 24),
          Row(
            children: [
              _buildInfoItem(
                  'Monto', '\$${monto.toStringAsFixed(2)}', Icons.savings),
              _buildInfoItem(
                  'Método',
                  (item['metodo_pago'] ?? 'Efectivo').toString().toUpperCase(),
                  Icons.payment),
              _buildInfoItem(
                  'Turno', '#${item['numero_turno'] ?? 'N/A'}', Icons.tag),
            ],
          ),
          if (item['comprobante_path'] != null &&
              (item['comprobante_path'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('COMPROBANTE / CAPTURE:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullImage(item['comprobante_path']),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: (item['comprobante_path'] as String).startsWith('http')
                      ? Image.network(
                          item['comprobante_path'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 40, color: Colors.grey)),
                        )
                      : (File(item['comprobante_path']).existsSync())
                          ? Image.file(
                              File(item['comprobante_path']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.broken_image,
                                          size: 40, color: Colors.grey)),
                            )
                          : const Center(
                              child: Icon(Icons.image_not_supported,
                                  size: 40, color: Colors.grey)),
                ),
              ),
            ),
          ],
        ],
      ),
      creador: creador,
    );
  }

  Widget _buildPremiumCard({
    required String tipo,
    required Map<String, dynamic> item,
    required String title,
    required String tag,
    required Widget content,
    required String creador,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      'Creado por: $creador',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildActionButtons(item, tipo),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOTAS / OBSERVACIONES:',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text(note,
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCreditRequestCard(Map<String, dynamic> item) {
    final double inversion = (item['costo_inversion'] ?? 0).toDouble();
    final double ganancia = (item['margen_ganancia'] ?? 0).toDouble();
    final double total = inversion + ganancia;
    final String concepto = item['concepto'] ?? 'Sin concepto';
    final String cliente = item['Clientes']?['nombre'] ?? 'N/A';
    final String creador =
        item['creado_por'] ?? item['usuario_nombre'] ?? 'Sistema';
    final String notas = item['notas'] ?? '';
    final int numCuotas = item['numero_cuotas'] ?? 1;

    // Cálculo de duración aproximada en meses
    String duracionStr = '';
    final int modalidadIdx = item['modalidad_pago'] ?? 0;
    if (modalidadIdx == 1) {
      // Semanal
      duracionStr = '${(numCuotas / 4).toStringAsFixed(1)} Meses';
    } else if (modalidadIdx == 2) {
      // Quincenal
      duracionStr = '${(numCuotas / 2).toStringAsFixed(1)} Meses';
    } else if (modalidadIdx == 3) {
      // Mensual
      duracionStr = '$numCuotas Meses';
    } else if (modalidadIdx == 0) {
      // Diario
      duracionStr = '${(numCuotas / 30).toStringAsFixed(1)} Meses';
    } else {
      duracionStr = 'Personalizado';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con degradado y Concepto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Concepto: $concepto',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Cuota simple',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del Cliente
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Cliente: $cliente',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Grid de Montos e Inversión
                Row(
                  children: [
                    _buildInfoItem(
                        'Inversión',
                        '\$${inversion.toStringAsFixed(2)}',
                        Icons.account_balance_wallet_outlined),
                    _buildInfoItem('Ganancia',
                        '\$${ganancia.toStringAsFixed(2)}', Icons.trending_up),
                    _buildInfoItem('Monto Total',
                        '\$${total.toStringAsFixed(2)}', Icons.monetization_on,
                        isTotal: true),
                  ],
                ),
                const SizedBox(height: 16),

                // Duración y Creador
                Row(
                  children: [
                    _buildSmallInfo(
                        Icons.calendar_today, 'Duración: $duracionStr'),
                    const SizedBox(width: 16),
                    _buildSmallInfo(Icons.edit_note, 'Cuotas: $numCuotas'),
                  ],
                ),

                if (notas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notas / Observaciones:',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(notas,
                            style: const TextStyle(
                                fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Calendario de Pagos (Colapsable o Resumido)
                _buildCompactSchedule(item['Cuotas'] as List? ?? []),

                const SizedBox(height: 16),

                // Footer con creador
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Creado por: $creador',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildActionButtons(item, 'credito'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {bool isTotal = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon,
              size: 20,
              color: isTotal ? AppColors.primaryGreen : Colors.grey[600]),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primaryGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildCompactSchedule(List cuotas) {
    if (cuotas.isEmpty) return const SizedBox.shrink();

    cuotas.sort((a, b) =>
        (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PLAN DE PAGOS:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cuotas.take(6).map((c) {
              final fecha =
                  DateFormat('dd/MM').format(DateTime.parse(c['fecha_pago']));
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$fecha: \$${((c['monto'] ?? 0) as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
          if (cuotas.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('... y ${cuotas.length - 6} cuotas más',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> item, String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aprobar'),
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
                child: url.startsWith('http')
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: const Text('Error al cargar la imagen'),
                        ),
                      )
                    : Image.file(
                        File(url),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                              'Imagen local no disponible en este dispositivo'),
                        ),
                      ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text('Aprobación Exitosa'),
                ],
              ),
              content: Text(
                  'El crédito ha sido aprobado y asignado a tu panel.\n\n¿Deseas asignárselo a ${creadorNombre ?? "el empleado"} para que lo gestione?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Más tarde')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white),
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
                orElse: () => Usuario(
                    nombreCompleto: creadorNombre, correoElectronico: ''),
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
          const SnackBar(
              content: Text('✅ Solicitud aprobada'),
              backgroundColor: Colors.green),
        );
      }
      _loadAllPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Error al aprobar: $e'),
              backgroundColor: Colors.red),
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
        content: const Text(
            '¿Estás seguro de que deseas rechazar esta solicitud? El registro será eliminado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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
          const SnackBar(
              content: Text('🚫 Solicitud rechazada'),
              backgroundColor: Colors.orange),
        );
      }
      _loadAllPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ Error al rechazar: $e'),
              backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
