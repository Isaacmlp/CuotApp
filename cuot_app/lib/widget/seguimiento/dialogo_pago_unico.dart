// lib/widget/seguimiento/dialogo_pago_unico.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cuot_app/utils/scrapper_util.dart'; // 👈 NUEVO: Scrapper
import 'package:cuot_app/Model/credito_unico_model.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';
import 'package:image_picker/image_picker.dart'; // 👈 NUEVO
import 'dart:io'; // 👈 NUEVO: Para manejar el File del path
import 'package:cuot_app/service/storage_service.dart'; // 👈 NUEVO

class DialogoPagoUnico extends StatefulWidget {
  final CreditoUnico credito;
  final bool esParcial;
  final Function(Pago) onPagoRealizado;

  const DialogoPagoUnico({
    super.key,
    required this.credito,
    required this.esParcial,
    required this.onPagoRealizado,
  });

  @override
  State<DialogoPagoUnico> createState() => _DialogoPagoUnicoState();
}

class _DialogoPagoUnicoState extends State<DialogoPagoUnico> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _montoController;
  late TextEditingController _tasaController; // 👈 NUEVO
  late TextEditingController _bsController; // 👈 NUEVO
  late TextEditingController _referenciaController;
  late TextEditingController _observacionesController;
  String _metodoPago = 'efectivo';
  DateTime _fechaPago = DateTime.now();
  bool _isLoadingTasa = false; // 👈 NUEVO: Estado de carga
  String? _comprobantePath; // 👈 NUEVO: Ruta del capture
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isUploading = false; // 👈 NUEVO: Estado de subida a Storage
  final StorageService _storageService = StorageService(); // 👈 NUEVO

  final List<Map<String, dynamic>> _metodosPago = [
    {'valor': 'efectivo', 'label': 'Efectivo', 'icon': Icons.money, 'color': Colors.green},
    {'valor': 'transferencia', 'label': 'Transferencia', 'icon': Icons.compare_arrows, 'color': Colors.blue},
    {'valor': 'pagomovil', 'label': 'Pago Móvil', 'icon': Icons.smartphone, 'color': Colors.red},
    {'valor': 'divisas', 'label': 'Divisas (E)', 'icon': Icons.attach_money, 'color': Colors.teal},
    {'valor': 'binance', 'label': 'Binance', 'icon': Icons.currency_bitcoin, 'color': Colors.black},
    {'valor': 'zelle', 'label': 'Zelle', 'icon': Icons.qr_code, 'color': Colors.purple},
  ];

  double get _maxMonto => widget.credito.saldoPendiente;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.esParcial 
          ? (_maxMonto / 2).toStringAsFixed(2)
          : _maxMonto.toStringAsFixed(2),
    );
    _tasaController = TextEditingController(); // 👈 NUEVO
    _bsController = TextEditingController(); // 👈 NUEVO
    _referenciaController = TextEditingController();
    _observacionesController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Más suave
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Efecto rebote suave corregido
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // Solo al inicio
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

  // 👈 NUEVO: Método para seleccionar el capture
  Future<void> _seleccionarComprobante() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Reducir calidad para ahorrar espacio
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32), // Igual al otro (32)
          ),
          elevation: 24,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Igual al otro
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85, // Igualado
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
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Center(
                        child: Column(
                          children: [
                            /*Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.credito.estadoColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.esParcial 
                                    ? Icons.payment_outlined
                                    : Icons.payment,
                                size: 40,
                                color: widget.credito.estadoColor,
                              ),
                            ),
                            */
                            const SizedBox(height: 12),
                            Text(
                              widget.esParcial 
                                  ? 'Pago Parcial'
                                  : 'Pago Completo',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.credito.concepto,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),                      const SizedBox(height: 20),
                      
                      // 1. Resumen Cliente
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cliente',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    widget.credito.nombreCliente,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 2. Info Cards
                      Row(
                        children: [
                          _buildInfoCard(
                            'Pagado',
                            '\$${widget.credito.totalPagado.toStringAsFixed(2)}',
                            AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            'Pendiente',
                            '\$${widget.credito.saldoPendiente.toStringAsFixed(2)}',
                            const Color(0xFFE8573D),
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
                              borderRadius: BorderRadius.circular(12),
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
                      
                      const SizedBox(height: 16),
                                                   

                      // 5. Campo de monto
                      // 5. Campo de monto
                      TextFormField(
                        controller: _montoController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        onChanged: (value) {
                          _updateBsFromUsd();
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: widget.esParcial
                              ? 'Monto a pagar (USD)'
                              : 'Monto total (USD)',
                          prefixText: '\$ ',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyToClipboard(_montoController.text, 'Monto USD'),
                            tooltip: 'Copiar USD',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // 6. Tasa del día
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
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tasa del día (BCV)',
                          prefixText: 'Bs. ',
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
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _cargarTasaBcv,
                                    tooltip: 'Refrescar Tasa',
                                  ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.05),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 7. Equivalente en Bolívares (Editable)
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
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      
                      /* 
                      if (widget.esParcial) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildMontoRapido(0.25)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMontoRapido(0.5)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMontoRapido(0.75)),
                          ],
                        ),
                      ],
                      */

                      const SizedBox(height: 16),
                      
                      // 4. Observaciones
                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Observaciones (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                  : Colors.grey.shade300,
                              width: 2,
                              style: _comprobantePath != null 
                                  ? BorderStyle.solid 
                                  : BorderStyle.solid, // Nota: No hay dashed nativo, simularé con estilo
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
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: const Icon(Icons.close, color: Colors.red, size: 20),
                                        ),
                                      ),
                                    ),
                                    const Center(
                                      child: Icon(
                                        Icons.check_circle,
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
                                        color: AppColors.primaryGreen.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cloud_upload_outlined, 
                                        color: AppColors.primaryGreen, 
                                        size: 40
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Toca aquí para subir el capture',
                                      style: TextStyle(
                                        color: AppColors.darkGrey.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG, PNG o Capture de pantalla',
                                      style: TextStyle(
                                        color: Colors.grey.shade400, 
                                        fontSize: 11
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // 👈 INTEGRADO: Resumen final de pago (ESTILO REUTILIZADO)
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
                                  '\$${(double.tryParse(_montoController.text) ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
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
                                      final montoUsd = double.tryParse(_montoController.text) ?? 0.0;
                                      final tasa = double.tryParse(_tasaController.text) ?? 0.0;
                                      return 'Bs. ${(montoUsd * tasa).toStringAsFixed(2)}';
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isUploading ? null : () => Navigator.pop(context),
                              child: const Text('CANCELAR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _confirmarPago,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                : const Text('CONFIRMAR'),
                            ),
                          ),
                        ],
                      ),
                    ], // Fin Inner Column children
                  ), // Fin Inner Column
                ), // Fin SingleChildScrollView
              ), // Fin Expanded
            ], // Fin Main Column children
          ), // Fin Main Column,
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mediumGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
      ),
    ),
  );
}

  Widget _buildInfoCard(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _confirmarPago() async {
    final monto = double.tryParse(_montoController.text) ?? 0;
    
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (monto > _maxMonto + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto no puede exceder el saldo pendiente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? comprobanteUrl;

    // 🚀 SUBIR A STORAGE SI HAY IMAGEN
    if (_comprobantePath != null) {
      setState(() => _isUploading = true);
      try {
        final nombreArchivo = 'pago_unico_${widget.credito.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
              duration: const Duration(seconds: 5), // Más tiempo para leer el error real
            ),
          );
        }
        setState(() => _isUploading = false);
        return;
      }
    }

    final nuevoPago = Pago(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      creditoId: widget.credito.id,
      numeroCuota: 1,
      fechaPago: widget.credito.fechaLimite,
      monto: monto,
      fechaPagoReal: _combinarFechaConHoraActual(_fechaPago),
      estado: 'pagado',
      metodoPago: _metodoPago,
      referencia: _referenciaController.text,
      observaciones: _observacionesController.text,
      comprobantePath: comprobanteUrl, // Solo la URL pública
    );

    widget.onPagoRealizado(nuevoPago);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}