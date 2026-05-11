// lib/widget/seguimiento/dialogo_pago_cuota_completo.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 NUEVO: Clipboard
import 'package:cuot_app/utils/scrapper_util.dart'; // 👈 NUEVO: Scrapper
import 'package:cuot_app/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:image_picker/image_picker.dart'; // 👈 NUEVO
import 'dart:io'; // 👈 NUEVO
import 'package:cuot_app/service/storage_service.dart'; // 👈 NUEVO

class DialogoPagoCuotaCompleto extends StatefulWidget {
  final int numeroCuota;
  final double monto;
  final double montoRestante; // 👈 NUEVO: monto que falta por pagar de esta cuota
  final DateTime fechaVencimiento;
  final String nombreCliente;
  final String concepto;
  final double montoPagadoHastaAhora;
  final double totalCredito;
  final int totalCuotas;
  final int cuotasPagadas;
  final bool esPagoParcial; // 👈 NUEVO: indica si es un pago parcial de una cuota
  final Function(
    double monto,
    DateTime fechaPago,
    String metodoPago,
    String referencia,
    String observaciones,
    bool aplicarMora,
    double? montoMora,
    bool esPagoParcial,
    String? comprobantePath, // 👈 NUEVO
  ) onPagar;

  const DialogoPagoCuotaCompleto({
    super.key,
    required this.numeroCuota,
    required this.monto,
    required this.montoRestante,
    required this.fechaVencimiento,
    required this.nombreCliente,
    required this.concepto,
    required this.montoPagadoHastaAhora,
    required this.totalCredito,
    required this.totalCuotas,
    required this.cuotasPagadas,
    this.esPagoParcial = false,
    required this.onPagar,
  });

  @override
  State<DialogoPagoCuotaCompleto> createState() => _DialogoPagoCuotaCompletoState();
}

class _DialogoPagoCuotaCompletoState extends State<DialogoPagoCuotaCompleto> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;
  late TextEditingController _tasaController; // 👈 NUEVO
  late TextEditingController _bsController; // 👈 NUEVO
  late TextEditingController _referenciaController;
  late TextEditingController _observacionesController;
  
  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'efectivo';
  late String _tipoPago;
  bool _aplicarMora = false;
  double _montoMora = 0.0;
  bool _isLoadingTasa = false; // 👈 NUEVO: Estado de carga
  String? _comprobantePath; // 👈 NUEVO: Ruta del capture
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isUploading = false; // 👈 NUEVO
  final StorageService _storageService = StorageService(); // 👈 NUEVO

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'pagomovil', 'label': 'Pago Móvil', 'icon': Icons.smartphone, 'color': Colors.red},
    {'valor': 'divisas', 'label': 'Divisas (E)', 'icon': Icons.attach_money, 'color': Colors.teal},
    {'valor': 'binance', 'label': 'Binance', 'icon': Icons.currency_bitcoin, 'color': Colors.black},
    {'valor': 'zelle', 'label': 'Zelle', 'icon': Icons.qr_code, 'color': Colors.purple},
  ];

  // Calcular días de atraso
  int get _diasAtraso {
    final hoy = DateTime.now();
    final fechaVencimiento = DateTime(
      widget.fechaVencimiento.year,
      widget.fechaVencimiento.month,
      widget.fechaVencimiento.day,
    );
    final fechaActual = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    );
    
    if (fechaActual.isAfter(fechaVencimiento)) {
      return fechaActual.difference(fechaVencimiento).inDays;
    }
    return 0;
  }

  // Calcular mora
  double get _moraCalculada {
    if (_diasAtraso > 0) {
      const tasaMoraDiaria = 0.005; // 0.5% por día
      return widget.monto * tasaMoraDiaria * _diasAtraso;
    }
    return 0.0;
  }

  // Total a pagar (CORREGIDO para pagos parciales)
  double get _totalAPagar {
    double total = 0.0;
    
    if (_tipoPago == 'completo') {
      total = widget.montoRestante; // 👈 Usar montoRestante en lugar de monto
    } else {
      total = double.tryParse(_montoController.text) ?? 0.0;
    }
    
    if (_aplicarMora && _diasAtraso > 0) {
      final moraAAplicar = _montoMora > 0 ? _montoMora : _moraCalculada;
      total += moraAAplicar;
    }
    
    return total;
  }

  // 👇 NUEVO: Monto que quedará pendiente después de este pago
  double get _montoPendienteDespues {
    if (_tipoPago == 'completo') return 0.0;
    
    final montoAPagar = double.tryParse(_montoController.text) ?? 0.0;
    return widget.montoRestante - montoAPagar;
  }

  double get _saldoRestanteCredito {
    return widget.totalCredito - (widget.montoPagadoHastaAhora + _totalAPagar);
  }

  // Validar monto de mora
  void _validarMontoMora(String value) {
    final nuevoMonto = double.tryParse(value) ?? 0;
    if (nuevoMonto >= 0) {
      setState(() {
        _montoMora = nuevoMonto;
      });
    }
  }

  // 👈 NUEVO: Lógica de conversión
  void _updateBsFromUsd() {
    final montoUsd = double.tryParse(_montoController.text) ?? 0.0;
    final tasa = double.tryParse(_tasaController.text) ?? 0.0;
    final bs = montoUsd * tasa;
    if (bs > 0) {
      _bsController.text = bs.toStringAsFixed(2);
    } else {
      _bsController.clear();
    }
  }

  void _updateUsdFromBs() {
    final montoBs = double.tryParse(_bsController.text) ?? 0.0;
    final tasa = double.tryParse(_tasaController.text) ?? 0.0;
    if (tasa > 0) {
      final usd = montoBs / tasa;
      // Actualizamos solo si NO es el modo completo bloqueado
      if (_tipoPago == 'parcial') {
        _montoController.text = usd.toStringAsFixed(2);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $label copiado al portapapeles'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tipoPago = widget.esPagoParcial ? 'parcial' : 'completo';
    _montoController = TextEditingController(
      text: widget.montoRestante.toStringAsFixed(2), // 👈 Usar montoRestante
    );
    _tasaController = TextEditingController(); // 👈 NUEVO
    _bsController = TextEditingController(); // 👈 NUEVO
    _referenciaController = TextEditingController();
    _observacionesController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Más suave
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // Solo al inicio
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Efecto rebote suave
    );
    _animationController.forward();
    
    // 👈 NUEVO: Intentar cargar la tasa automáticamente
    _cargarTasaBcv();
  }

  // 👈 NUEVO: Método para cargar la tasa del BCV
  Future<void> _cargarTasaBcv() async {
    setState(() => _isLoadingTasa = true);
    final tasa = await ScrapperUtil.getDolarBcv();
    if (mounted && tasa != null) {
      setState(() {
        _tasaController.text = tasa.toStringAsFixed(4);
        _isLoadingTasa = false;
        // _updateBsFromUsd(); // 👈 ELIMINADO para iniciar vacío
      });
    } else if (mounted) {
      setState(() => _isLoadingTasa = false);
    }
  }

  // 👈 NUEVO: Método para seleccionar el capture
  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      setState(() {
        _comprobantePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose(); // 👈 NUEVO
    _bsController.dispose(); // 👈 NUEVO
    _referenciaController.dispose();
    _observacionesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime _combinarFechaConHoraActual(DateTime date) {
    final now = DateTime.now();
    // Si la fecha elegida es HOY, usamos el 'now' completo para tener la hora exacta del momento.
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return now;
    }
    // Si es otra fecha, la dejamos como está (probablemente 00:00:00 del picker)
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 24,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primaryGreen.withOpacity(0.03),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título con icono animado
                        Center(
                          child: Column(
                            children: [
                              /*
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                  size: 45,
                                ),
                              ),
                              */
                              const SizedBox(height: 16),
                              Text(
                                'Registrar Pago',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Cuota #${widget.numeroCuota} de ${widget.totalCuotas}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.esPagoParcial) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Pago Parcial - Resta: \$${widget.montoRestante.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                            const SizedBox(height: 20),

                        // 1. Tarjeta de información del cliente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppColors.info.withOpacity(0.1),
                                child: Text(
                                  widget.nombreCliente[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.nombreCliente,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.concepto,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.mediumGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 2. Grid de información de la cuota
                        Row(
                          children: [
                            _buildInfoCard(
                              'Monto Total',
                              '\$${widget.monto.toStringAsFixed(2)}',
                              AppColors.primaryGreen,
                              Icons.payments,
                            ),
                            const SizedBox(width: 12),
                              _buildInfoCard(
                                'Restante',
                                '\$${widget.montoRestante.toStringAsFixed(2)}',
                                const Color(0xFFE8573D),
                                Icons.pending,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            _buildInfoCard(
                              'Vencimiento',
                              DateFormat('dd/MM/yyyy').format(widget.fechaVencimiento),
                              _diasAtraso > 0 ? AppColors.error : AppColors.info,
                              Icons.event,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoCard(
                              'Atraso',
                              _diasAtraso > 0 
                                  ? '$_diasAtraso día${_diasAtraso != 1 ? 's' : ''}' 
                                  : 'Al día',
                              _diasAtraso > 0 ? AppColors.error : AppColors.success,
                              Icons.access_time,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        
                        // 3. Métodos de pago
                        const Text(
                          'Método de pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _metodoPago,
                          items: _metodosPago.map((metodo) {
                            return DropdownMenuItem<String>(
                              value: metodo['valor'],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (metodo['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      metodo['icon'],
                                      color: metodo['color'],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    metodo['label'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _metodoPago = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.mediumGrey),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        
                        // 2. Campo de referencia condicional
                        if (_metodoPago == 'transferencia' || 
                            _metodoPago == 'pagomovil' || 
                            _metodoPago == 'zelle' ||
                            _metodoPago == 'binance') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _referenciaController,
                            decoration: InputDecoration(
                              labelText: 'Referencia',
                              hintText: 'Ej: 1234',
                              prefixIcon: const Icon(Icons.confirmation_number_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // 3. Fecha de pago
                        CustomDatePicker(
                          selectedDate: _fechaPago,
                          onDateSelected: (date) {
                            setState(() {
                              _fechaPago = date;
                            });
                          },
                          label: 'Fecha de pago',
                        ),
                        
                        // 4. Observaciones
                        

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),

                        // 5. Tipo de pago (AHORA ABAJO)
                        const Text(
                          'Tipo de pago',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTipoPagoButton(
                                'Completo',
                                'completo',
                                Icons.check_circle,
                                widget.montoRestante,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTipoPagoButton(
                                'Parcial',
                                'parcial',
                                Icons.payment,
                                widget.montoRestante,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 6. Monto
                        TextFormField(
                          controller: _montoController,
                          enabled: _tipoPago == 'parcial',
                          decoration: InputDecoration(
                            labelText: _tipoPago == 'completo' 
                                ? 'Monto a pagar' 
                                : 'Monto a pagar (parcial)',
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            suffixIcon: _tipoPago == 'completo'
                                ? Icon(
                                    Icons.lock,
                                    color: Colors.grey.shade400,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed: () => _copyToClipboard(_montoController.text, 'Monto USD'),
                                    tooltip: 'Copiar USD',
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: _tipoPago == 'completo'
                                ? Colors.grey.shade100
                                : Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateBsFromUsd(); // 👈 NUEVO
                            setState(() {}); // Forzar reconstrucción para actualizar Bs.
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el monto';
                            }
                            final monto = double.tryParse(value);
                            if (monto == null || monto <= 0) {
                              return 'Monto inválido';
                            }
                            if (_tipoPago == 'completo' && (monto - widget.montoRestante).abs() > 0.01) {
                              return 'El monto debe ser \$${widget.montoRestante.toStringAsFixed(2)}';
                            }
                            if (_tipoPago == 'parcial' && monto > widget.montoRestante + 0.01) {
                              return 'No puede exceder el restante de \$${widget.montoRestante.toStringAsFixed(2)}';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 7. Tasa del día
                        TextFormField(
                          controller: _tasaController,
                          onChanged: (value) {
                            _updateBsFromUsd();
                            setState(() {});
                          },
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: 1.2,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tasa del día (BCV)',
                            prefixText: 'Bs. ',
                            prefixStyle: const TextStyle(fontSize: 18, color: Colors.blue),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  onPressed: () => _copyToClipboard(_tasaController.text, 'Tasa'),
                                  tooltip: 'Copiar Tasa',
                                ),
                                _isLoadingTasa 
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.refresh, size: 28),
                                      onPressed: _cargarTasaBcv,
                                      tooltip: 'Refrescar tasa BCV',
                                    ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.blue.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 8. Equivalente en Bolívares
                        TextFormField(
                          controller: _bsController,
                          onChanged: (value) {
                            _updateUsdFromBs();
                            setState(() {});
                          },
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                          decoration: InputDecoration(
                            labelText: 'EQUIVALENTE EN BOLÍVARES',
                            prefixText: 'Bs. ',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () => _copyToClipboard(_bsController.text, 'Monto Bs'),
                              tooltip: 'Copiar Bs',
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                        SizedBox(height: 16),

                        TextFormField(
                          controller: _observacionesController,
                          maxLines: 1,
                          decoration: InputDecoration(
                            labelText: 'Observaciones (opcional)',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 👈 MEJORADO: Sección de Capture
                        const Text(
                          'Comprobante de Pago (Capture)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isUploading ? null : _seleccionarComprobante,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: _comprobantePath != null 
                                  ? Colors.transparent 
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _comprobantePath != null 
                                    ? AppColors.primaryGreen.withOpacity(0.5)
                                    : Colors.grey.shade200,
                                width: 2,
                              ),
                              boxShadow: _comprobantePath != null ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: _comprobantePath != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.file(
                                          File(_comprobantePath!),
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(22),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _comprobantePath = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.red, size: 20),
                                          ),
                                        ),
                                      ),
                                      const Center(
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add_photo_alternate_outlined, 
                                          color: AppColors.primaryGreen, 
                                          size: 40
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Toca aquí para subir el capture',
                                        style: TextStyle(
                                          color: AppColors.darkGrey.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Formatos soportados: JPG, PNG',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                                                                        
                        // 👇 NUEVO: Mostrar cuánto quedará pendiente después del pago parcial
                        if (_tipoPago == 'parcial' && _montoPendienteDespues > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quedará pendiente: \$${_montoPendienteDespues.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // 9. Alerta de mora (si está atrasado)
                        if (_diasAtraso > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: AppColors.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cuota vencida',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          Text(
                                            'Atraso de $_diasAtraso día${_diasAtraso != 1 ? 's' : ''}. '
                                            'Mora sugerida: \$${_moraCalculada.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _aplicarMora,
                                      onChanged: (value) {
                                        setState(() {
                                          _aplicarMora = value;
                                          if (value && _montoMora == 0) {
                                            _montoMora = _moraCalculada;
                                          }
                                        });
                                      },
                                      activeColor: AppColors.error,
                                    ),
                                  ],
                                ),
                                
                                if (_aplicarMora) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _montoMora.toStringAsFixed(2),
                                          decoration: InputDecoration(
                                            labelText: 'Monto de mora',
                                            prefixText: '\$ ',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: _validarMontoMora,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Mora sugerida: \$${_moraCalculada.toStringAsFixed(2)}',
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Resumen de pago
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total a pagar:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '\$${_totalAPagar.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total en Bolívares:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      () {
                                        final tasa = double.tryParse(_tasaController.text) ?? 0.0;
                                        return 'Bs. ${(_totalAPagar * tasa).toStringAsFixed(2)}';
                                      }(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Pagado hasta ahora:',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${widget.montoPagadoHastaAhora.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Saldo restante:',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '\$${_saldoRestanteCredito.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _saldoRestanteCredito > 0 
                                          ? AppColors.warning 
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isUploading ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isUploading ? null : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isUploading = true);
                                    
                                    final monto = double.parse(_montoController.text);
                                    final esPagoParcial = _tipoPago == 'parcial' && 
                                        (monto < widget.montoRestante - 0.01);
                                    
                                    String? comprobanteUrl;
                                    
                                    // 🚀 UPLOAD TO STORAGE
                                    if (_comprobantePath != null) {
                                      try {
                                        final nombreArchivo = 'pago_cuota_${widget.numeroCuota}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                        comprobanteUrl = await _storageService.subirCaptura(
                                          File(_comprobantePath!), 
                                          nombreArchivo
                                        );

                                        if (comprobanteUrl == null) {
                                          throw Exception('La subida finalizó sin URL');
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error al subir comprobante: $e'),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 5),
                                            ),
                                          );
                                        }
                                        setState(() => _isUploading = false);
                                        return;
                                      }
                                    }

                                    widget.onPagar(
                                      monto,
                                      _combinarFechaConHoraActual(_fechaPago),
                                      _metodoPago,
                                      _referenciaController.text,
                                      _observacionesController.text,
                                      _aplicarMora,
                                      _aplicarMora ? _montoMora : null,
                                      esPagoParcial,
                                      comprobanteUrl ?? _comprobantePath,
                                    );
                                    
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isUploading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'CONFIRMAR PAGO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ), // Fin Inner Column
                  ), // Fin Form
                ), // Fin SingleChildScrollView
              ), // Fin Expanded
                  ],
                ), // Fin Main Column
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mediumGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ), // Fin Stack
          ), // Fin Container
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String valor, Color color, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icono, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoPagoButton(String label, String valor, IconData icono, double montoRestante) {
    final isSelected = _tipoPago == valor;
    final bool deshabilitado = valor == 'completo' && montoRestante <= 0;
    
    return Opacity(
      opacity: deshabilitado ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: deshabilitado
            ? null
            : () {
                setState(() {
                  _tipoPago = valor;
                  if (valor == 'completo') {
                    _montoController.text = montoRestante.toStringAsFixed(2);
                  }
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected && !deshabilitado
                ? LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                    ],
                  )
                : null,
            color: isSelected && !deshabilitado ? null : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected && !deshabilitado
                  ? Colors.transparent
                  : AppColors.primaryGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 18,
                color: isSelected && !deshabilitado
                    ? Colors.white
                    : AppColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected && !deshabilitado
                      ? Colors.white
                      : AppColors.primaryGreen,
                  fontWeight: isSelected && !deshabilitado
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}