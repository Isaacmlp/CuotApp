import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/service/renovacion_service.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/Model/renovacion_model.dart';
import 'package:intl/intl.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/user_admin_service.dart';
import 'package:cuot_app/widget/creditos/custom_date_picker.dart';

class FormularioRenovacionPage extends StatefulWidget {
  final String creditoId;
  final String nombreUsuario;
  final String? nombreLogueado;
  final bool esModoTrabajo;
  final String? rolActual;

  const FormularioRenovacionPage({
    super.key,
    required this.creditoId,
    required this.nombreUsuario,
    this.nombreLogueado,
    this.esModoTrabajo = false,
    this.rolActual,
  });

  @override
  State<FormularioRenovacionPage> createState() =>
      _FormularioRenovacionPageState();
}

class _FormularioRenovacionPageState extends State<FormularioRenovacionPage> {
  final _formKey = GlobalKey<FormState>();
  final CreditService _creditService = CreditService();
  final RenovacionService _renovacionService = RenovacionService();

  // Datos del préstamo original
  Map<String, dynamic>? _credito;
  bool _isLoading = true;
  bool _isSaving = false;

  // Campos del formulario
  // Campos del formulario
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _abonoController =
      TextEditingController(text: '0');
  final TextEditingController _observacionesController =
      TextEditingController();
  final TextEditingController _moraManualController =
      TextEditingController(text: '0');
  bool _incluirMora = false;

  // Para Pago Único
  DateTime? _fechaLimiteNueva;

  // Fecha de renovación (global para cálculo de mora)
  DateTime? _fechaRenovacion;
  DateTime? _fechaInicioRenovacion; // 👈 NUEVO: Fecha de inicio de la renovación

  // Ganancia diaria original para cálculo de mora
  double _gananciaDiariaOriginal = 0;

  // Para Cuotas (Editables)
  List<Map<String, dynamic>> _cuotasEditables = [];
  bool _moraEditadaManualmente = false; // 👈 NUEVO: Bandera para proteger edición manual

  // Datos calculados
  double _costoInversion = 0;
  double _saldoPendiente = 0;
  double _montoOriginal = 0;
  double _cuotaActual = 0;
  int _plazoOriginal = 0;
  int _plazoDiasOriginal = 0;
  double _moraCalculada = 0;
  String _modalidadOriginal = '';
  String _tipoCredito = ''; // 'unico' o 'cuotas'

  String? _rolUsuario;
  String? _adminResponsable;

  @override
  void initState() {
    super.initState();
    _loadCreditData();
    _cargarDatosUsuario();

    // Listeners para auto-ajuste de cuotas
    _abonoController.addListener(_onParametroCambiado);
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final service = UserAdminService();
      final users = await service.listarUsuarios();
      
      // Búsqueda más segura ignorando espacios y mayúsculas
      final currentUser = users.firstWhere(
        (u) => u.nombre.trim().toLowerCase() == widget.nombreUsuario.trim().toLowerCase(),
        orElse: () => Usuario(
          nombreCompleto: widget.nombreUsuario,
          correoElectronico: '',
          rol: 'empleado', // Si no lo encuentra, asume empleado por seguridad
          creadoPor: 'admin',
        ),
      );
      
      if (mounted) {
        setState(() {
          _rolUsuario = currentUser.rol;
          _adminResponsable = currentUser.creadoPor ?? widget.nombreUsuario;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos de usuario: $e');
      if (mounted) {
        setState(() {
          _rolUsuario = 'empleado'; // Fallback seguro
          _adminResponsable = 'admin';
        });
      }
    }
  }

  void _onParametroCambiado() {
    if (_tipoCredito == 'cuotas' && _cuotasEditables.isNotEmpty) {
      _repartirMontoEntreCuotas();
    }
    // Sincronizar el controlador de mora solo si no ha sido editado manualmente
    if (!_moraEditadaManualmente) {
      _moraManualController.text = _moraSugerida.toStringAsFixed(2);
    }
    setState(() {});
  }

  void _repartirMontoEntreCuotas() {
    if (_cuotasEditables.isEmpty) return;

    final double totalTotal = _montoTotalCalculado;

    // 1. Calcular cunto ya está "ocupado" por cuotas bloqueadas
    double montoBloqueado = 0;
    int numNoBloqueadas = 0;
    for (var c in _cuotasEditables) {
      if (c['bloqueada'] == true) {
        montoBloqueado += (double.tryParse(c['controller'].text) ?? 0);
      } else {
        numNoBloqueadas++;
      }
    }

    if (numNoBloqueadas == 0) return; // No hay donde repartir

    final double montoRestante = totalTotal - montoBloqueado;
    final double montoPorCuota =
        (montoRestante > 0 ? montoRestante : 0) / numNoBloqueadas;

    setState(() {
      for (var cuota in _cuotasEditables) {
        if (cuota['bloqueada'] != true) {
          cuota['controller'].text = montoPorCuota.toStringAsFixed(2);
        }
      }
    });
  }

  void _agregarCuota() {
    DateTime nuevaFecha;
    if (_cuotasEditables.isNotEmpty) {
      final ultimaFecha = _cuotasEditables.last['fecha'] as DateTime;
      nuevaFecha = ultimaFecha.add(_getModalityDuration(_modalidadOriginal));
    } else {
      nuevaFecha = DateTime.now().add(_getModalityDuration(_modalidadOriginal));
    }

    setState(() {
      _cuotasEditables.add({
        'id': null, // Nueva cuota no tiene ID de DB
        'monto': 0.0,
        'fecha': nuevaFecha,
        'controller': TextEditingController(text: '0.00'),
      });
      _repartirMontoEntreCuotas();
    });
  }

  void _quitarCuota() {
    if (_cuotasEditables.length > 1) {
      final last = _cuotasEditables.last;
      if (last['bloqueada'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes eliminar una cuota que ya tiene abonos'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _cuotasEditables.removeLast();
        last['controller'].dispose();
        _repartirMontoEntreCuotas();
      });
    }
  }

  Duration _getModalityDuration(String modality) {
    switch (modality.toLowerCase()) {
      case 'diario':
        return const Duration(days: 1);
      case 'semanal':
        return const Duration(days: 7);
      case 'quincenal':
        return const Duration(days: 15);
      case 'mensual':
      default:
        return const Duration(days: 30);
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _abonoController.dispose();
    _observacionesController.dispose();
    _moraManualController.dispose();
    for (var c in _cuotasEditables) {
      c['controller'].dispose();
    }
    super.dispose();
  }

  Future<void> _loadCreditData() async {
    try {
      final data = await _creditService.getCreditById(widget.creditoId);
      if (data != null) {
        final double costoInversion =
            (data['costo_inversion'] as num).toDouble();
        final double margenGanancia =
            (data['margen_ganancia'] as num).toDouble();
        final double totalCredito = costoInversion + margenGanancia;

        final List<dynamic> rawPagos = data['Pagos'] ?? [];

        // Determinar la fecha de la última renovación para excluir pagos históricos.
        // Tras una renovación el gross en DB es el nuevo saldo limpio, por lo que
        // solo los pagos POSTERIORES a la renovación deben contarse.
        final List<dynamic> rawRenovaciones = data['Renovaciones'] ?? [];
        DateTime? ultimaRenovacionFecha;
        if (rawRenovaciones.isNotEmpty) {
          final sorted = List<dynamic>.from(rawRenovaciones)
            ..sort((a, b) {
              final dateA = DateTime.parse(a['created_at'] ?? a['fecha_renovacion']);
              final dateB = DateTime.parse(b['created_at'] ?? b['fecha_renovacion']);
              return dateB.compareTo(dateA);
            });
          final last = sorted.first;
          ultimaRenovacionFecha =
              DateTime.parse(last['created_at'] ?? last['fecha_renovacion']);
        }

        double totalPagado = 0;
        for (var pago in rawPagos) {
          final ref = pago['referencia']?.toString() ?? '';
          // Excluir abonos de renovación (ya están en el gross) y pagos anteriores
          if (ref == 'Abono en Renovación') continue;
          if (ultimaRenovacionFecha != null) {
            final fechaStr =
                pago['fecha_pago_real'] ?? pago['fecha_pago'];
            final fechaPago = fechaStr != null
                ? DateTime.tryParse(fechaStr.toString())
                : null;
            if (fechaPago != null) {
              // Comparación por momento exacto: Un pago es histórico si ocurrió antes de la renovación.
              // Esto permite abonos el mismo día post-renovación, pero ignora abonos previos a la renovación.
              if (fechaPago.isBefore(ultimaRenovacionFecha)) continue;
            }
          }
          totalPagado += (pago['monto'] as num).toDouble();
        }

        final List<dynamic> rawCuotas = data['Cuotas'] ?? [];
        double moraCalculada = 0;
        final hoy = DateTime.now();
        final List<Map<String, dynamic>> pendingCuotas = [];

        DateTime fechaOriginal;
        if (data['tipo_credito'] == 'unico' && data['fecha_vencimiento'] != null) {
          fechaOriginal = DateTime.parse(data['fecha_vencimiento']);
        } else if (rawCuotas.isNotEmpty) {
          final List<dynamic> sorted = List.from(rawCuotas)..sort((a,b)=> (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));
          fechaOriginal = DateTime.parse(sorted.last['fecha_pago'].toString());
        } else {
          fechaOriginal = data['fecha_inicio'] != null ? DateTime.parse(data['fecha_inicio']) : hoy;
        }

        // Calcular días de plazo original
        int plazoDias = 30;
        if (data['fecha_inicio'] != null) {
          final start = DateTime.parse(data['fecha_inicio']);
          // Conteo INCLUSIVO (+1) y UTC para el plazo original
          final startUtc = DateTime.utc(start.year, start.month, start.day);
          final endUtc = DateTime.utc(fechaOriginal.year, fechaOriginal.month, fechaOriginal.day);
          plazoDias = endUtc.difference(startUtc).inDays + 1;
          if (plazoDias <= 0) plazoDias = 30;
        }

        final double gananciaDiariaOriginal = margenGanancia / plazoDias;

        // Calcular mora inicial (retraso hasta hoy)
        final hoyMidnight = DateTime(hoy.year, hoy.month, hoy.day);
        final fechaOriMidnight = DateTime(fechaOriginal.year, fechaOriginal.month, fechaOriginal.day);
        if (fechaOriMidnight.isBefore(hoyMidnight)) {
          final int diasRetraso = hoyMidnight.difference(fechaOriMidnight).inDays;
          moraCalculada = diasRetraso * gananciaDiariaOriginal;
        }

        for (var cuota in rawCuotas) {
          if (cuota['pagada'] != true) {
            final numeroCuota = cuota['numero_cuota'];
            final bool tieneAbonos =
                rawPagos.any((p) => p['numero_cuota'] == numeroCuota);

            final fecha = DateTime.parse(cuota['fecha_pago']);
            pendingCuotas.add({
              'id': cuota['id'],
              'monto': (cuota['monto'] as num).toDouble(),
              'fecha': fecha,
              'bloqueada': tieneAbonos,
              'numero': numeroCuota,
              'controller': TextEditingController(
                  text: (cuota['monto'] as num).toStringAsFixed(2)),
            });
          }
        }

        if (!mounted) return;
        setState(() {
          _credito = data;
          _costoInversion = costoInversion;
          _tipoCredito = data['tipo_credito'] ?? 'cuotas';
          _montoOriginal = totalCredito;
          _saldoPendiente = totalCredito - totalPagado;
          _plazoOriginal = data['numero_cuotas'] ?? 1;
          _plazoDiasOriginal = plazoDias;
          _gananciaDiariaOriginal = gananciaDiariaOriginal;

          if (_tipoCredito == 'unico') {
            final fechaLimiteStr =
                data['fecha_vencimiento'] ?? (data['fecha_inicio'] != null ? DateTime.parse(data['fecha_inicio']).add(const Duration(days: 30)).toIso8601String() : DateTime.now().toIso8601String());
            _fechaLimiteNueva =
                DateTime.parse(fechaLimiteStr).add(const Duration(days: 30));
            _fechaRenovacion = _fechaLimiteNueva;
            _fechaInicioRenovacion = DateTime.parse(fechaLimiteStr); // De inicio es la fecha de vencimiento original
          } else {
            _fechaRenovacion = DateTime.now().add(const Duration(days: 1));
            _fechaInicioRenovacion = DateTime.now();
          }

          _cuotaActual =
              _plazoOriginal > 0 ? totalCredito / _plazoOriginal : totalCredito;
          _moraCalculada = moraCalculada;
          _moraManualController.text = moraCalculada > 0 ? _moraSugerida.toStringAsFixed(2) : '0.00';
          _modalidadOriginal = data['modalidad_pago']?.toString() ?? 'mensual';
          _cuotasEditables = pendingCuotas;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error cargando crédito: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _abono {
    return double.tryParse(_abonoController.text) ?? 0;
  }

  double get _montoMora {
    return double.tryParse(_moraManualController.text) ?? 0;
  }

  double get _montoCuotasEditadas {
    double total = 0;
    for (var cuota in _cuotasEditables) {
      total += double.tryParse(cuota['controller'].text) ?? 0;
    }
    return total;
  }

  double get _moraSugerida {
    if (_fechaRenovacion == null || _credito == null) {
      return _moraCalculada;
    }

    try {
      DateTime fechaOriginal;
      if (_tipoCredito == 'unico' && _credito?['fecha_vencimiento'] != null) {
        fechaOriginal = DateTime.parse(_credito!['fecha_vencimiento']);
      } else {
        final List<dynamic> cuotas = _credito?['Cuotas'] ?? [];
        if (cuotas.isNotEmpty) {
          final List<dynamic> sorted = List.from(cuotas)..sort((a,b)=> (a['numero_cuota'] as int).compareTo(b['numero_cuota'] as int));
          fechaOriginal = DateTime.parse(sorted.last['fecha_pago'].toString());
        } else {
          fechaOriginal = _credito?['fecha_inicio'] != null ? DateTime.parse(_credito!['fecha_inicio']) : DateTime.now();
        }
      }

      final fechaRenovMidnight = DateTime.utc(_fechaRenovacion!.year, _fechaRenovacion!.month, _fechaRenovacion!.day);
      final fechaIniRenovMidnight = _fechaInicioRenovacion != null 
          ? DateTime.utc(_fechaInicioRenovacion!.year, _fechaInicioRenovacion!.month, _fechaInicioRenovacion!.day)
          : DateTime.utc(fechaOriginal.year, fechaOriginal.month, fechaOriginal.day);

      final int diasDiferencia = fechaRenovMidnight.difference(fechaIniRenovMidnight).inDays + 1;
      
      // Cálculo proporcional: le restamos el abono al monto base antes de sacar la mora
      final double baseCalculo = _saldoPendiente - _abono;
      final double baseProporcional = baseCalculo > 0 ? baseCalculo : 0;
      
      // Tasa diaria original basada en el Capital (Costo de Inversión)
      // Ejemplo: (4 profit / 20 capital) / 15 días originales = 1.33% diario
      final double tasaDiaria = _costoInversion > 0 
          ? ((_gananciaDiariaOriginal / _costoInversion)) 
          : 0;
      
      return diasDiferencia > 0 ? (baseProporcional * tasaDiaria * diasDiferencia) : 0;
    } catch (e, stackTrace) {
      debugPrint('Error calculando mora sugerida: $e');
      debugPrint('$stackTrace');
      return 0;
    }
  }

  double get _montoTotalCalculado {
    double total = _saldoPendiente + (_incluirMora ? _montoMora : 0) - _abono;
    return total > 0 ? total : 0;
  }

  double get _nuevoMontoTotal {
    return _montoTotalCalculado;
  }

  double get _nuevaCuota {
    if (_tipoCredito == 'unico') return _nuevoMontoTotal;
    if (_cuotasEditables.isEmpty) return 0;
    // En cuotas, la "cuota" es variable, pero para el resumen mostramos el promedio
    // o simplemente quitamos este concepto si el usuario edita cada una.
    return _nuevoMontoTotal / _cuotasEditables.length;
  }

  double get _totalPagarActual {
    return _saldoPendiente;
  }

  double get _totalPagarNuevo {
    return _nuevoMontoTotal;
  }



  Future<void> _guardarRenovacion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un motivo de renovación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_tipoCredito == 'cuotas') {
      final double totalCuotas = _montoCuotasEditadas;
      final double totalEsperado = _montoTotalCalculado;

      if ((totalCuotas - totalEsperado).abs() > 0.01) {
        final diff = totalCuotas - totalEsperado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'La suma no coincide: ${diff > 0 ? "Sobran" : "Faltan"} \$${diff.abs().toStringAsFixed(2)} del nuevo total (\$${totalEsperado.toStringAsFixed(2)})'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // NUEVAS VALIDACIONES: Evitar saldo cero y abono excesivo
    final totalConMora = _saldoPendiente + (_incluirMora ? _montoMora : 0);
    if (_abono >= totalConMora) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ El abono no puede cubrir el total del saldo. Para liquidar el préstamo, registre un pago normal.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_nuevoMontoTotal < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ El nuevo total del préstamo debe ser mayor a \$1.00'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cliente = _credito!['Clientes'];
      final clienteId = cliente['id'];

      final List<Map<String, dynamic>> cuotasParaGuardar =
          _cuotasEditables.map((c) {
        return {
          'id': c['id'],
          'monto': double.tryParse(c['controller'].text) ?? 0,
          'fecha': (c['fecha'] as DateTime).toIso8601String(),
        };
      }).toList();

      // DETERMINAR ROL PARA LA RENOVACIÓN
      final String? rolParaRenovacion = (widget.rolActual == 'empleado' && widget.esModoTrabajo) 
          ? 'empleado' 
          : 'admin';

      final renovacion = Renovacion(
        creditoOriginalId: widget.creditoId,
        clienteId: clienteId,
        motivo: _motivoController.text.trim(),
        condicionesAnteriores: {
          'plazo': _plazoOriginal,
          'plazo_dias': _plazoDiasOriginal,
          'cuota': _tipoCredito == 'unico' ? null : _cuotaActual,
          'saldo_pendiente': _saldoPendiente,
          'monto_total': _montoOriginal,
          'costo_inversion': _costoInversion,
          'modalidad': _modalidadOriginal,
          'tipo_credito': _tipoCredito,
          'fecha_inicio': _credito?['fecha_inicio'],
          'fecha_vencimiento': _credito?['fecha_vencimiento'],
          'cuotas_anteriores': _credito?['Cuotas'],
        },
        condicionesNuevas: {
          'tipo_credito': _tipoCredito,
          'monto_total': _nuevoMontoTotal,
          'abono': _abono,
          'plazo': _tipoCredito == 'unico' ? 1 : _cuotasEditables.length,
          'incluye_mora': _incluirMora,
          'monto_mora': _incluirMora ? _montoMora : 0,
          'fecha_renovacion': DateTime.now().toIso8601String(),
          if (_tipoCredito == 'unico') ...{
            'fecha_inicio_nueva': _fechaInicioRenovacion?.toIso8601String(),
            'fecha_pago_nueva': _fechaLimiteNueva?.toIso8601String(),
            'plazo_dias_nuevo': _fechaInicioRenovacion != null && _fechaLimiteNueva != null 
                ? DateTime.utc(_fechaLimiteNueva!.year, _fechaLimiteNueva!.month, _fechaLimiteNueva!.day)
                    .difference(DateTime.utc(_fechaInicioRenovacion!.year, _fechaInicioRenovacion!.month, _fechaInicioRenovacion!.day))
                    .inDays + 1 
                : 1,
          },
          if (_tipoCredito == 'cuotas') ...{
            'fecha_inicio_nueva': _fechaInicioRenovacion?.toIso8601String(),
            'cuotas_renovadas': cuotasParaGuardar,
          }
        },
        nuevoPlazo: _tipoCredito == 'unico' ? 1 : _cuotasEditables.length,
        unidadPlazo: _tipoCredito == 'unico' ? 'pago_unico' : 'cuotas',
        nuevaTasaInteres: 0,
        nuevoMontoCuota: _nuevaCuota,
        montoAbono: _abono,
        incluirMora: _incluirMora,
        montoMora: _incluirMora ? _montoMora : 0,
        usuarioAutoriza: _adminResponsable ?? widget.nombreUsuario,
        estado: (rolParaRenovacion == 'empleado') ? 'pendiente' : 'aprobada',
        creadoPor: widget.nombreLogueado ?? widget.nombreUsuario,
        observaciones: _observacionesController.text.trim(),
      );

      await _renovacionService.crearRenovacion(renovacion);
      
      // 🎯 REGISTRO EN BITÁCORA
      final String nombreCliente = cliente['nombre'] ?? 'N/A';
      final String numCredito = _credito?['numero_credito']?.toString() ?? 'S/N';
      await BitacoraService().registrarActividad(
        usuarioNombre: widget.nombreUsuario,
        accion: 'renovacion_credito',
        descripcion: 'Renovó préstamo #$numCredito para $nombreCliente. Nuevo total: \$${_nuevoMontoTotal.toStringAsFixed(2)}',
        entidadTipo: 'credito',
        entidadId: widget.creditoId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rolParaRenovacion == 'empleado' 
                ? '🕒 Renovación solicitada. En espera de aprobación.' 
                : '✅ Renovación completada con éxito'),
            backgroundColor: rolParaRenovacion == 'empleado' ? Colors.orange : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar renovación: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateMoraController() {
    _moraManualController.text = _moraSugerida.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Renovación de Préstamo'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_credito == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Renovación de Préstamo'),
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Error al cargar el préstamo')),
      );
    }

    final cliente = _credito!['Clientes'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Renovación de Préstamo'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === DATOS DEL PRÉSTAMO ORIGINAL (CUADRO ROJO SOLICITADO) ===
              _buildSectionTitle('📋 Condiciones Originales', AppColors.error),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildReadOnlyRow(
                          Icons.person, 'Cliente', cliente['nombre'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.inventory, 'Producto',
                          _credito!['concepto'] ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.calendar_today, 'Fecha Inicio',
                          _credito!['fecha_inicio'] != null 
                              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_credito!['fecha_inicio']))
                              : 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.event_busy, 'Fecha Vencimiento',
                          _credito!['fecha_vencimiento'] != null 
                              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_credito!['fecha_vencimiento']))
                              : 'N/A'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.timer_outlined, 'Plazo Original',
                          '$_plazoDiasOriginal días'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.attach_money, 'Inversión',
                          '\$${_costoInversion.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.trending_up, 'Ganancia Pactada',
                          '\$${(_montoOriginal - _costoInversion).toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildReadOnlyRow(Icons.payments, 'Monto Total',
                          '\$${_montoOriginal.toStringAsFixed(2)}', isBold: true),
                      const Divider(height: 24),
                      _buildReadOnlyRow(Icons.warning_amber, 'Saldo Pendiente Actual',
                          '\$${_saldoPendiente.toStringAsFixed(2)}',
                          color: AppColors.error, isBold: true),
                      
                      if (_tipoCredito == 'cuotas' && _credito!['Cuotas'] != null) ...[
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Cuotas Anteriores:', 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (_credito!['Cuotas'] as List).length,
                            itemBuilder: (context, i) {
                              final c = _credito!['Cuotas'][i];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('#${c['numero_cuota']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text('\$${(c['monto'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === CONDICIONES DE RENOVACIÓN ===
              _buildSectionTitle(
                  '⚙️ Nuevas Condiciones', AppColors.primaryGreen),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === SECCIÓN DINÁMICA SEGÚN TIPO ===
                      if (_tipoCredito == 'unico') ...[
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            key: ValueKey('${_fechaInicioRenovacion?.millisecondsSinceEpoch}_${_fechaLimiteNueva?.millisecondsSinceEpoch}'),
                            onTap: () async {
                              final pickedRange = await showDialog<DateTimeRange>(
                                context: context,
                                builder: (context) => _DateRangeStepperDialog(
                                  initialStart: _fechaInicioRenovacion,
                                  initialEnd: _fechaLimiteNueva,
                                ),
                              );

                              if (pickedRange != null && mounted) {
                                setState(() {
                                  _fechaInicioRenovacion = pickedRange.start;
                                  _fechaLimiteNueva = pickedRange.end;
                                  _fechaRenovacion = pickedRange.end;
                                  _moraEditadaManualmente = false; 
                                  _updateMoraController();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                      ? AppColors.primaryGreen.withOpacity(0.5)
                                      : Colors.grey.shade300,
                                  width: _fechaInicioRenovacion != null && _fechaLimiteNueva != null ? 2 : 1,
                                ),
                                boxShadow: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGreen.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month, 
                                    color: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                        ? AppColors.primaryGreen
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rango de Renovación', 
                                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(
                                          _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                              ? '${DateFormat('dd/MM/yyyy').format(_fechaInicioRenovacion!)} - ${DateFormat('dd/MM/yyyy').format(_fechaLimiteNueva!)}'
                                              : 'Toca para seleccionar fechas',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                                ? AppColors.primaryGreen
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                          ? AppColors.primaryGreen.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                          ? '${DateTime.utc(_fechaLimiteNueva!.year, _fechaLimiteNueva!.month, _fechaLimiteNueva!.day).difference(DateTime.utc(_fechaInicioRenovacion!.year, _fechaInicioRenovacion!.month, _fechaInicioRenovacion!.day)).inDays + 1} días'
                                          : '-',
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: _fechaInicioRenovacion != null && _fechaLimiteNueva != null
                                            ? AppColors.primaryGreen
                                            : Colors.grey, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Nueva Fecha Vencimiento (Calculada de la última cuota)
                        CustomDatePicker(
                          selectedDate: _cuotasEditables.isEmpty 
                              ? null 
                              : (_cuotasEditables.last['fecha'] as DateTime?),
                          label: 'Nueva Fecha Vencimiento (Automática)',
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('Editar Cuotas Pendientes',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cuotasEditables.length,
                          itemBuilder: (context, index) {
                            final cuota = _cuotasEditables[index];
                            final bool isLocked = cuota['bloqueada'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isLocked
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isLocked
                                        ? Colors.grey
                                        : AppColors.primaryGreen,
                                    child: isLocked
                                        ? const Icon(Icons.lock,
                                            color: Colors.white, size: 14)
                                        : Text(
                                            '${cuota['numero'] ?? (index + 1)}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: cuota['controller'],
                                      enabled: !isLocked,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        prefixText: '\$ ',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        fillColor: isLocked
                                            ? Colors.grey.shade100
                                            : Colors.white,
                                        filled: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: CustomDatePicker(
                                      selectedDate: cuota['fecha'],
                                      onDateSelected: isLocked ? null : (picked) {
                                        setState(() {
                                          _cuotasEditables[index]['fecha'] = picked;
                                        });
                                      },
                                      label: 'Fecha',
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _quitarCuota,
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18),
                                label: const Text('Quitar Cuota',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                      color: AppColors.error.withOpacity(0.5)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _agregarCuota,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 18),
                                label: const Text('Agregar Cuota',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryGreen,
                                  side: BorderSide(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.5)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],



                      const SizedBox(height: 10),

                      const SizedBox(height: 16),
                      const Text('Abono en la Renovación (\$)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _abonoController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText: '0.00',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final abono = double.tryParse(value);
                            if (abono == null || abono < 0) {
                              return 'Monto inválido';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Checkbox Incluir Mora
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _incluirMora,
                              activeColor: AppColors.error,
                              onChanged: (val) {
                                setState(() {
                                  _incluirMora = val ?? false;
                                  if (_tipoCredito == 'cuotas')
                                    _repartirMontoEntreCuotas();
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '¿Desea incluir una ganancia extra en esta renovación?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_incluirMora) ...[
                        const SizedBox(height: 16),
                        // Monto de Mora (Editable)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ganancia Extra a Incluir (\$)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                              'Sugerido: \$${_moraSugerida.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _moraManualController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            hintText: 'Ej: 5.00',
                          ),
                          onChanged: (val) {
                            setState(() {
                              _moraEditadaManualmente = true; // 👈 Marcamos que el usuario editó el campo
                              if (_tipoCredito == 'cuotas') {
                                _repartirMontoEntreCuotas();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final n = double.tryParse(value);
                            if (n == null) return 'Monto inválido';
                            if (n < 0) return 'Solo valores positivos';
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Motivo
                      const Text('Motivo de Renovación *',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _motivoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          hintText:
                              'Ej: Cliente solicita ampliación de plazo...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el motivo';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Observaciones (opcional)
                      
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === TABLA COMPARATIVA ===
              _buildSectionTitle('📊 Comparativa', AppColors.darkGreen),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    columnWidths: {
                      0: const FlexColumnWidth(1.2),
                      1: const FlexColumnWidth(2),
                      2: const FlexColumnWidth(2),
                      if (_tipoCredito != 'unico') 3: const FlexColumnWidth(2),
                    },
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        children: [
                          _buildTableCell('', isHeader: true),
                          _buildTableCell('Plazo', isHeader: true),
                          _buildTableCell('Total', isHeader: true),
                          if (_tipoCredito != 'unico')
                            _buildTableCell('Cuota', isHeader: true),
                        ],
                      ),
                      // Fila VIEJO
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.red.shade100.withOpacity(0.4),
                        ),
                        children: [
                          _buildTableCell('Viejo', isBold: true, color: Colors.red.shade900),
                          _buildTableCell(
                            _tipoCredito == 'unico'
                                ? '$_plazoDiasOriginal días'
                                : '$_plazoOriginal cuotas',
                          ),
                          _buildTableCell(
                            '\$${_totalPagarActual.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          if (_tipoCredito != 'unico')
                            _buildTableCell('\$${_cuotaActual.toStringAsFixed(2)}'),
                        ],
                      ),
                      // Fila NUEVO
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                        ),
                        children: [
                          _buildTableCell('Nuevo', isBold: true, color: Colors.green.shade900),
                          _buildTableCell(
                            _tipoCredito == 'unico'
                                ? (_fechaLimiteNueva != null && _fechaInicioRenovacion != null
                                    ? '${DateTime.utc(_fechaLimiteNueva!.year, _fechaLimiteNueva!.month, _fechaLimiteNueva!.day).difference(DateTime.utc(_fechaInicioRenovacion!.year, _fechaInicioRenovacion!.month, _fechaInicioRenovacion!.day)).inDays + 1} días'
                                    : 'N/A')
                                : '${_cuotasEditables.length} cuotas',
                            color: AppColors.primaryGreen,
                          ),
                          _buildTableCell(
                            '\$${_totalPagarNuevo.toStringAsFixed(2)}',
                            isBold: true,
                            color: AppColors.primaryGreen,
                          ),
                          if (_tipoCredito != 'unico')
                            _buildTableCell(
                              '\$${_nuevaCuota.toStringAsFixed(2)}',
                              color: AppColors.primaryGreen,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Resumen de cálculo
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                color: AppColors.veryLightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalcRow('Saldo Pendiente', _saldoPendiente),
                      if (_abono > 0)
                        _buildCalcRow('- Abono aplicado', -_abono,
                            color: AppColors.error),
                      if (_incluirMora && _montoMora > 0)
                        _buildCalcRow('+ Ganancia extra', _montoMora,
                            color: AppColors.success),
                      const Divider(),
                      _buildCalcRow('NUEVO TOTAL PRÉSTAMO', _nuevoMontoTotal,
                          isBold: true, color: AppColors.primaryGreen),
                      if (_tipoCredito != 'unico')
                        _buildCalcRow(
                            'Nueva Cuota (${_cuotasEditables.length} cuotas)',
                            _nuevaCuota,
                            isBold: true,
                            color: AppColors.darkGreen),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // === BOTONES ===
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.mediumGrey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _guardarRenovacion,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          _isSaving ? 'Guardando...' : 'Guardar Renovación'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value,
      {Color? color, bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false,
      bool isBold = false,
      Color? color,
      Color? backgroundColor}) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 13 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? AppColors.darkGreen : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, double value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// 🌓 DIÁLOGO PERSONALIZADO PARA RANGO DE FECHAS ANIMADO
class _DateRangeStepperDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _DateRangeStepperDialog({this.initialStart, this.initialEnd});

  @override
  State<_DateRangeStepperDialog> createState() => _DateRangeStepperDialogState();
}

class _DateRangeStepperDialogState extends State<_DateRangeStepperDialog> {
  late DateTime _selectedStart;
  late DateTime _selectedEnd;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _selectedStart = widget.initialStart ?? DateTime.now();
    _selectedEnd = widget.initialEnd ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 8,
      child: Container(
        width: 350,
        height: 520,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Header con indicador de pasos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentStep == 0 ? 'Fecha de Inicio' : 'Fecha de Vencimiento',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      Text(
                        '${_currentStep + 1}/2',
                        style: TextStyle(
                          color: AppColors.primaryGreen.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Barra de progreso animada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 2,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.primaryGreen,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // Contenido principal (Calendarios)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Controlamos el scroll con botones
                onPageChanged: (v) => setState(() => _currentStep = v),
                children: [
                  // Paso 1: Inicio
                  CalendarDatePicker(
                    initialDate: _selectedStart,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (d) => setState(() => _selectedStart = d),
                  ),
                  // Paso 2: Final
                  CalendarDatePicker(
                    initialDate: _selectedStart.isAfter(_selectedEnd) ? _selectedStart : _selectedEnd,
                    firstDate: _selectedStart, // No puede ser antes del inicio
                    lastDate: DateTime(2100),
                    onDateChanged: (d) => setState(() => _selectedEnd = d),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400), 
                        curve: Curves.easeInOutBack
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                         minimumSize: Size.zero,
                      ),
                      child: const Text('VOLVER'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep == 0) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500), 
                          curve: Curves.easeInOutQuint
                        );
                      } else {
                        Navigator.pop(context, DateTimeRange(start: _selectedStart, end: _selectedEnd));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(80, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentStep == 0 ? 'SIGUIENTE' : 'CONFIRMAR',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
}
