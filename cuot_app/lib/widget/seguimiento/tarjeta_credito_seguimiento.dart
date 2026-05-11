// lib/widget/seguimiento/tarjeta_credito_seguimiento.dart
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/seguimiento/cuota_miniatura.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota.dart';

class TarjetaCreditoSeguimiento extends StatefulWidget {
  final Credito credito;
  final List<CuotaPersonalizada> cuotas;
  final List<Pago> pagos;
  final double montoAbonado;
  final VoidCallback onVerHistorial;

  const TarjetaCreditoSeguimiento({
    super.key,
    required this.credito,
    required this.cuotas,
    required this.pagos,
    required this.montoAbonado,
    required this.onVerHistorial,
  });

  @override
  State<TarjetaCreditoSeguimiento> createState() => _TarjetaCreditoSeguimientoState();
}

class _TarjetaCreditoSeguimientoState extends State<TarjetaCreditoSeguimiento> {
  bool _expandido = false;

  double get _montoPendiente => widget.credito.precioTotal - widget.montoAbonado;
  double get _porcentajeAvance => widget.credito.precioTotal > 0 
      ? (widget.montoAbonado / widget.credito.precioTotal) 
      : 0;

  Color get _estadoColor {
    if (_montoPendiente <= 0) return AppColors.success;
    if (_porcentajeAvance > 0.7) return AppColors.warning;
    return AppColors.primaryGreen;
  }

  String get _estadoTexto {
    if (_montoPendiente <= 0) return 'Pagado';
    if (widget.credito.estaVencido) return 'Atrasado';
    return 'Al día';
  }

  bool _cuotaPagada(int numeroCuota) {
    return widget.pagos.any((p) => p.numeroCuota == numeroCuota);
  }

  void _mostrarDialogoPago(CuotaPersonalizada cuota) {
   
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _estadoColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Cabecera siempre visible
            InkWell(
              onTap: () {
                setState(() {
                  _expandido = !_expandido;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Fila superior: Concepto, cliente y estado
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.credito.concepto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.credito.nombreCliente,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mediumGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _estadoColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _estadoTexto,
                            style: TextStyle(
                              color: _estadoColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _expandido 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          color: AppColors.primaryGreen,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barra de progreso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mediumGrey,
                              ),
                            ),
                            Text(
                              '${(_porcentajeAvance * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _estadoColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _porcentajeAvance.clamp(0.0, 1.0),
                            backgroundColor: AppColors.lightGrey,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _estadoColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Montos principales
                    Row(
                      children: [
                        Expanded(
                          child: _buildMontoItem(
                            'Total',
                            '\$${widget.credito.precioTotal.toStringAsFixed(2)}',
                            AppColors.primaryGreen,
                          ),
                        ),
                        Expanded(
                          child: _buildMontoItem(
                            'Abonado',
                            '\$${widget.montoAbonado.toStringAsFixed(2)}',
                            AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _buildMontoItem(
                            'Pendiente',
                            '\$${_montoPendiente.toStringAsFixed(2)}',
                            _montoPendiente > 0 ? AppColors.warning : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Sección expandible con cuotas
            if (_expandido) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(color: AppColors.lightGrey),
                    bottom: BorderSide(color: AppColors.lightGrey),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cuotas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grid de miniaturas de cuotas
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: widget.cuotas.length,
                      itemBuilder: (context, index) {
                        final cuota = widget.cuotas[index];
                        final pagada = _cuotaPagada(cuota.numeroCuota);
                        
                        return CuotaMiniatura(
                          numeroCuota: cuota.numeroCuota,
                          fecha: cuota.fechaPago,
                          monto: cuota.monto,
                          pagada: pagada,
                          onTap: pagada ? null : () => _mostrarDialogoPago(cuota),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Leyenda
                    Row(
                      children: [
                        _buildLeyenda(AppColors.success, 'Pagada'),
                        const SizedBox(width: 16),
                        _buildLeyenda(AppColors.warning, 'Pendiente'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botones de acción rápida
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAccionBoton(
                        icon: Icons.payment,
                        label: 'Pagar Cuota',
                        onTap: () {
                          // Buscar primera cuota pendiente
                          final primeraPendiente = widget.cuotas.firstWhere(
                            (c) => !_cuotaPagada(c.numeroCuota),
                            orElse: () => widget.cuotas.first,
                          );
                          _mostrarDialogoPago(primeraPendiente);
                        },
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAccionBoton(
                        icon: Icons.history,
                        label: 'Historial',
                        onTap: widget.onVerHistorial,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontoItem(String label, String monto, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          monto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccionBoton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.mediumGrey,
          ),
        ),
      ],
    );
  }
}