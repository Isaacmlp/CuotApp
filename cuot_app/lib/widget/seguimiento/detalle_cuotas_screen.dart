// lib/widget/seguimiento/detalle_cuotas_screen.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota.dart';

class DetalleCuotasScreen extends StatefulWidget {
  final Credito credito;
  final List<CuotaPersonalizada> cuotas;
  final List<Pago> pagos;

  const DetalleCuotasScreen({
    super.key,
    required this.credito,
    required this.cuotas,
    required this.pagos,
  });

  @override
  State<DetalleCuotasScreen> createState() => _DetalleCuotasScreenState();
}

class _DetalleCuotasScreenState extends State<DetalleCuotasScreen> {
  late List<CuotaPersonalizada> _cuotas;
  late List<Pago> _pagos;
  String _filtroEstado = 'todas';

  @override
  void initState() {
    super.initState();
    _cuotas = List.from(widget.cuotas);
    _cuotas.sort((a, b) => a.numeroCuota.compareTo(b.numeroCuota));
    _pagos = widget.pagos;
  }

  List<CuotaPersonalizada> get _cuotasFiltradas {
    if (_filtroEstado == 'todas') return _cuotas;
    if (_filtroEstado == 'pendientes') {
      return _cuotas.where((c) => !_estaPagada(c)).toList();
    }
    if (_filtroEstado == 'pagadas') {
      return _cuotas.where((c) => _estaPagada(c)).toList();
    }
    return _cuotas;
  }

  bool _estaPagada(CuotaPersonalizada cuota) {
    return cuota.pagada;
  }

  Pago? _obtenerPagoDeCuota(CuotaPersonalizada cuota) {
    var index = _pagos.indexWhere((p) => p.numeroCuota == cuota.numeroCuota);
    return index != -1 ? _pagos[index] : null;
  }

  double get _totalPagado {
    return _pagos.fold(0, (sum, pago) => sum + pago.monto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cuotas - ${widget.credito.concepto}'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
            ),
            child: Column(
              children: [
                // Resumen rápido
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResumenItem(
                      'Total',
                      '\$${widget.credito.precioTotal.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                    _buildResumenItem(
                      'Pagado',
                      '\$${_totalPagado.toStringAsFixed(2)}',
                      AppColors.success,
                    ),
                    _buildResumenItem(
                      'Pendiente',
                      '\$${(widget.credito.precioTotal - _totalPagado).toStringAsFixed(2)}',
                      AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Filtros
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildFiltroChip('Todas', 'todas'),
                      _buildFiltroChip('Pendientes', 'pendientes'),
                      _buildFiltroChip('Pagadas', 'pagadas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _cuotasFiltradas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 64,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cuotas ${_filtroEstado == 'pagadas' ? 'pagadas' : 'pendientes'}',
                    style: TextStyle(color: AppColors.mediumGrey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cuotasFiltradas.length,
              itemBuilder: (context, index) {
                final cuota = _cuotasFiltradas[index];
                final pagada = _estaPagada(cuota);
                final pago = pagada ? _obtenerPagoDeCuota(cuota) : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: pagada ? 1 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: pagada
                        ? BorderSide.none
                        : BorderSide(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                          ),
                  ),
                  child: InkWell(
                    onTap: pagada
                        ? null
                        : () => print("hola"),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: pagada
                            ? AppColors.success.withOpacity(0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          // Número de cuota
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: pagada
                                  ? AppColors.success.withOpacity(0.2)
                                  : AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${cuota.numeroCuota}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: pagada
                                      ? AppColors.success
                                      : AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Detalles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: pagada
                                          ? AppColors.success
                                          : AppColors.mediumGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vence: ${cuota.fechaFormateada}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: pagada
                                            ? AppColors.success
                                            : AppColors.darkGrey,
                                        fontWeight: pagada
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      size: 14,
                                      color: pagada
                                          ? AppColors.success
                                          : AppColors.mediumGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Monto: \$${cuota.monto.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: pagada
                                            ? AppColors.success
                                            : AppColors.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                if (pagada && pago != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pagado: ${pago.fechaFormateada}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Estado y acción
                          if (pagada)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pagada',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => print("hola"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(70, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Pagar'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildResumenItem(String label, String valor, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final isSelected = _filtroEstado == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtroEstado = valor;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryGreen : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*void _mostrarDialogoPago(CuotaPersonalizada cuota) {
    showDialog(
      context: context,
      builder: (context) => DialogoPagarCuota(
        cuota: cuota,
        nombreCliente: widget.credito.nombreCliente,
        concepto: widget.credito.concepto,
        onPagoRealizado: (pago) {
          setState(() {
            _pagos.add(pago);
          });
        },
      ),
    );
  }*/
}