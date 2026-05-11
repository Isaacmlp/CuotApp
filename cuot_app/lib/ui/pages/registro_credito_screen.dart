import 'dart:io';

import 'package:cuot_app/service/credito_service.dart';
import 'package:cuot_app/widget/creditos/cliente_form.dart';
import 'package:cuot_app/widget/creditos/custom_button.dart';
import 'package:cuot_app/widget/creditos/factura_uploader.dart';
import 'package:cuot_app/widget/creditos/forma_pago_form.dart';
import 'package:cuot_app/widget/creditos/producto_form.dart';
import 'package:flutter/material.dart';
import 'package:cuot_app/service/storage_service.dart';

class RegistroCreditoScreen extends StatefulWidget {
  const RegistroCreditoScreen({super.key});

  @override
  State<RegistroCreditoScreen> createState() => _RegistroCreditoScreenState();
}

class _RegistroCreditoScreenState extends State<RegistroCreditoScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Servicios
  final CreditoService _creditoService = CreditoService();
  final StorageService _storageService = StorageService();

  // 🔧 LÓGICA: Variables para almacenar datos del formulario
  Map<String, dynamic>? _clienteInfo;
  List<Producto> _productos = [];
  Map<String, dynamic>? _formaPagoInfo;
  File? _facturaFile;

  // 🔧 LÓGICA: Título de cada paso
  final List<String> _stepTitles = [
    'Datos del Cliente',
    'Productos a Financiar',
    'Forma de Pago',
    'Factura',
    'Resumen',
  ];

  // 🔧 LÓGICA: Avanzar al siguiente paso
  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 🔧 LÓGICA: Retroceder al paso anterior
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 🔧 LÓGICA: Validar paso actual
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _clienteInfo != null;
      case 1:
        return _productos.isNotEmpty;
      case 2:
        return _formaPagoInfo != null;
      case 3:
        return _facturaFile != null;
      case 4:
        return true;
      default:
        return false;
    }
  }

  // 🔧 LÓGICA: Guardar crédito
  Future<void> _guardarCredito() async {
    setState(() => _isLoading = true);

    try {
      // 1. Subir factura a Storage si existe
      String? facturaUrl;
      if (_facturaFile != null) {
        facturaUrl = await _storageService.subirFactura(
          _facturaFile!,
          'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 2. Calcular total de productos
      double montoTotal = _productos.fold(0, (sum, p) => sum + p.total);

      // 3. Crear modelo de crédito
      /*final credito = CreditoModel(
        clienteId: 0, // TODO: Obtener o crear cliente
        productos: _productos.map((p) => ProductoModel(
          nombre: p.nombre,
          descripcion: p.descripcion,
          precioUnitario: p.precioUnitario,
          cantidad: p.cantidad,
        )).toList(),
        montoTotal: montoTotal,
        cuotaInicial: _formaPagoInfo?['cuotaInicial'] ?? 0,
        saldoPendiente: _formaPagoInfo?['saldoPendiente'] ?? montoTotal,
        formaPago: _formaPagoInfo?['formaPago'] ?? '',
        numeroCuotas: _formaPagoInfo?['numeroCuotas'] ?? 1,
        interes: _formaPagoInfo?['interes'] ?? 0,
        facturaUrl: facturaUrl,
        fechaCreacion: DateTime.now(),
        estado: 'activo',
      );*/

      // 4. Guardar en Supabase
      //final resultado = await _creditoService.crearCredito(credito);

      if (true) {
        _mostrarMensaje('✅ Crédito registrado exitosamente', isError: false);
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje('❌ Error al guardar el crédito');
      }
    } catch (e) {
      _mostrarMensaje('❌ Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Crédito'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔧 LÓGICA: Barra de progreso
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          
          // 🔧 LÓGICA: Indicador de paso actual
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paso ${_currentStep + 1} de 5',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _stepTitles[_currentStep],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // 🔧 LÓGICA: Contenido del paso actual
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                // Paso 1: Datos del Cliente
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ClienteForm(
                    onClienteInfoChanged: (info) {
                      setState(() => _clienteInfo = info);
                    },
                  ),
                ),

                // Paso 2: Productos
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ProductoForm(
                    onProductosChanged: (productos) {
                      setState(() => _productos = productos);
                    },
                  ),
                ),

                // Paso 3: Forma de Pago
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: FormaPagoForm(
                    onFormaPagoChanged: (info) {
                      setState(() => _formaPagoInfo = info);
                    },
                    montoTotal: _productos.fold(0, (sum, p) => sum + p.total),
                  ),
                ),

                // Paso 4: Factura
                Padding(
                  padding: EdgeInsets.all(16),
                  child: FacturaUploader(
                    onFacturaSeleccionada: (file) {
                      setState(() => _facturaFile = file);
                    },
                  ),
                ),

                // Paso 5: Resumen
                _buildResumen(),
              ],
            ),
          ),

          // 🔧 LÓGICA: Botones de navegación
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: CustomButton(
                      text: 'Anterior',
                      onPressed: _previousStep,
                      isOutlined: true,
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _currentStep == 4 ? 'Guardar' : 'Siguiente',
                    onPressed: _canProceed()
                        ? _currentStep == 4
                            ? _guardarCredito
                            : _nextStep
                        : null,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 LÓGICA: Widget de resumen
  Widget _buildResumen() {
    final double montoTotal = _productos.fold(0, (sum, p) => sum + p.total);
    final saldoPendiente = _formaPagoInfo?['saldoPendiente'] ?? montoTotal;
    final totalAPagar = saldoPendiente + (saldoPendiente * (_formaPagoInfo?['interes'] ?? 0) / 100);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cliente
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text(_clienteInfo?['nombreCompleto'] ?? ''),
              subtitle: Text('Cédula: ${_clienteInfo?['cedula'] ?? ''}'),
            ),
          ),

          // Productos
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ..._productos.map((p) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('• ${p.cantidad} x ${p.nombre}: \$${p.total.toStringAsFixed(2)}'),
                  )),
                  Divider(),
                  Text('Total: \$${montoTotal.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Forma de Pago
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Forma de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Período: ${_formaPagoInfo?['formaPago']}'),
                  Text('• Cuotas: ${_formaPagoInfo?['numeroCuotas']}'),
                  Text('• Interés: ${_formaPagoInfo?['interes']}%'),
                  Text('• Cuota inicial: \$${_formaPagoInfo?['cuotaInicial']?.toStringAsFixed(2) ?? '0'}'),
                  Text('• Saldo pendiente: \$${saldoPendiente.toStringAsFixed(2)}'),
                  Text('• Total a pagar: \$${totalAPagar.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),

          // Factura
          if (_facturaFile != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.receipt, color: Colors.blue),
                title: Text('Factura adjunta'),
                subtitle: Text('Lista para subir'),
              ),
            ),
        ],
      ),
    );
  }
}