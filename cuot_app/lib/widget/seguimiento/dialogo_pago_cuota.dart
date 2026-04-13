import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/service/storage_service.dart';
import 'package:cuot_app/utils/scrapper_util.dart';

class DialogoPagoCuota extends StatefulWidget {
  final int numeroCuota;
  final double monto;
  final DateTime fechaVencimiento;
  final String nombreCliente;
  final Function(double, DateTime, String, String?) onPagar; // 👈 ACTUALIZADO: String? comprobantePath

  const DialogoPagoCuota({
    super.key,
    required this.numeroCuota,
    required this.monto,
    required this.fechaVencimiento,
    required this.nombreCliente,
    required this.onPagar,
  });

  @override
  State<DialogoPagoCuota> createState() => _DialogoPagoCuotaState();
}

class _DialogoPagoCuotaState extends State<DialogoPagoCuota> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _montoController;
  late TextEditingController _tasaController;
  late TextEditingController _bsController;
  DateTime _fechaPago = DateTime.now();
  String _metodoPago = 'efectivo';
  String? _comprobantePath;
  bool _isLoadingTasa = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isUploading = false; // 👈 NUEVO
  final StorageService _storageService = StorageService(); // 👈 NUEVO

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'pagomovil', 'label': 'Pago móvil', 'icon': Icons.credit_card, 'color': Colors.red},
    {'valor': 'zelle', 'label': 'Zelle', 'icon': Icons.qr_code, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.monto.toStringAsFixed(2));
    _tasaController = TextEditingController();
    _bsController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Cargar tasa automáticamente
    _cargarTasaBcv();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _tasaController.dispose();
    _bsController.dispose();
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

  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _comprobantePath = image.path;
      });
    }
  }

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
      _montoController.text = usd.toStringAsFixed(2);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $label copiado al portapapeles'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 24,
        shadowColor: AppColors.primaryGreen.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppColors.primaryGreen.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con diseño mejorado
                Stack(
                  children: [
                    /*Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 40,
                      ),
                    )*/
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Pagar Cuota #${widget.numeroCuota}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    widget.nombreCliente,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Info de vencimiento
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vence: ${widget.fechaVencimiento.day}/${widget.fechaVencimiento.month}/${widget.fechaVencimiento.year}',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Campo de monto USD
                TextFormField(
                  controller: _montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto a pagar (USD)',
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(_montoController.text, 'Monto USD'),
                      tooltip: 'Copiar USD',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: AppColors.success,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  onChanged: (value) {
                    _updateBsFromUsd();
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el monto';
                    }
                    final monto = double.tryParse(value);
                    if (monto == null || monto <= 0) {
                      return 'Monto inválido';
                    }
                    if (monto > widget.monto + 0.01) {
                      return 'No puede exceder la cuota';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),

                // Campo de Tasa
                TextFormField(
                  controller: _tasaController,
                  onChanged: (value) {
                    _updateBsFromUsd();
                    setState(() {});
                  },
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tasa del día (BCV)',
                    prefixText: 'Bs. ',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => _copyToClipboard(_tasaController.text, 'Tasa'),
                          tooltip: 'Copiar Tasa',
                        ),
                        _isLoadingTasa 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _cargarTasaBcv,
                              tooltip: 'Refrescar Tasa',
                            ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.blue.withOpacity(0.05),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Campo de monto Bs
                TextFormField(
                  controller: _bsController,
                  onChanged: (value) {
                    _updateUsdFromBs();
                    setState(() {});
                  },
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Equivalente en Bolívares',
                    prefixText: 'Bs. ',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(_bsController.text, 'Monto Bs'),
                      tooltip: 'Copiar Bs',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.success.withOpacity(0.05),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.success, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                
                // Selector de método de pago
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Método de pago',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mediumGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                          borderSide: BorderSide(color: AppColors.success, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.mediumGrey),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Selector de fecha
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(), // 👈 Siempre inicia el calendario en HOY
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: AppColors.success,
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.success,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      if (!mounted) return;
                      setState(() {
                        _fechaPago = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de pago',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mediumGrey,
                              ),
                            ),
                            Text(
                              '${_fechaPago.day}/${_fechaPago.month}/${_fechaPago.year}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 👈 MEJORADO: Sección de comprobante (Capture)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Comprobante de pago (Capture)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isUploading ? null : _seleccionarComprobante,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 150,
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
                                      height: 150,
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
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _comprobantePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.red, size: 18),
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_rounded, 
                                    color: AppColors.primaryGreen.withOpacity(0.5), 
                                    size: 36
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Toca para subir el capture',
                                    style: TextStyle(
                                      color: AppColors.mediumGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Opcional',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Botones
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
                            ),
                          ),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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
                            String? comprobanteUrl;

                            // 🚀 SUBIR A STORAGE SI HAY IMAGEN
                            if (_comprobantePath != null) {
                              try {
                                final nombreArchivo = 'pago_cuota_simple_${widget.numeroCuota}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                comprobanteUrl = await _storageService.subirCaptura(
                                  File(_comprobantePath!), 
                                  nombreArchivo
                                );
                                if (comprobanteUrl == null) {
                                  throw Exception('La subida finalizó sin URL (Error desconocido)');
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
                                Icon(Icons.check_circle, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'PAGAR',
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
            ),
          ),
        ),
      ),
    );
  }
}