import 'package:cuot_app/Model/credito_unico_model.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota_completo.dart';
import 'package:cuot_app/widget/seguimiento/tarjeta_credito_unico.dart';
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/cuota_personalizada.dart';
import 'package:cuot_app/Model/pago_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/seguimiento/tarjeta_financiamiento.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:cuot_app/ui/pages/dashboard_screen.dart';
import 'package:cuot_app/ui/pages/detalle_credito_page.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/widget/seguimiento/tarjeta_grupo.dart';
import 'package:cuot_app/ui/pages/savings/grupo_dashboard_page.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';

class SeguimientoCreditosPage extends StatefulWidget {
  final String nombreUsuario;
  final bool modoTrabajador;
  final String rol;
  final String correo;

  const SeguimientoCreditosPage({
    super.key,
    required this.nombreUsuario,
    this.modoTrabajador = false,
    this.rol = 'cliente',
    this.correo = '',
  });

  @override
  State<SeguimientoCreditosPage> createState() =>
      _SeguimientoCreditosPageState();
}

class _SeguimientoCreditosPageState extends State<SeguimientoCreditosPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CreditService _creditService = CreditService();
  final SavingsService _savingsService = SavingsService();
  List<dynamic> _financiamientos = [];
  List<Map<String, dynamic>> _grupos = [];
  String? _adminNombre; // 👈 NUEVO: Nombre del administrador dueño de los créditos
  bool _isLoading = true;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> rawCredits;
      List<Map<String, dynamic>> rawGroups;

      if (widget.modoTrabajador) {
        // Modo trabajador: cargar créditos compartidos
        final compartidoService = CreditoCompartidoService();
        final asignados = await compartidoService.obtenerCreditosAsignados(widget.nombreUsuario);

        // 1. Obtener Créditos
        final idsCreditos = asignados
            .where((a) => a.tipoEntidad == 'credito')
            .map((a) => a.creditoId)
            .toList();
        
        final batchCredits = await _creditService.getCreditsByIds(idsCreditos);
        
        rawCredits = [];
        for (var a in asignados.where((a) => a.tipoEntidad == 'credito')) {
          if (_adminNombre == null && a.propietarioNombre.isNotEmpty) _adminNombre = a.propietarioNombre;
          final creditData = batchCredits.firstWhere((c) => c['id'].toString() == a.creditoId, orElse: () => {});
          if (creditData.isNotEmpty) {
            final Map<String, dynamic> creditCopy = Map<String, dynamic>.from(creditData);
            creditCopy['permiso_compartido'] = a.permisos;
            rawCredits.add(creditCopy);
          }
        }

        // 2. Obtener Grupos de Ahorro
        final idsGrupos = asignados
            .where((a) => a.tipoEntidad == 'grupo_ahorro')
            .map((a) => a.creditoId)
            .toList();

        rawGroups = [];
        for (var id in idsGrupos) {
          final grupo = await _savingsService.getGrupoById(id);
          if (grupo != null) {
            final a = asignados.firstWhere((asig) => asig.creditoId == id);
            final json = grupo.toJson();
            json['permiso_compartido'] = a.permisos;
            // Para mostrar miembros también, necesitamos cargarlos
            final miembros = await _savingsService.getGruposConMiembros(a.propietarioNombre);
            final grupoConMiembros = miembros.firstWhere((m) => m['id'].toString() == id, orElse: () => json);
            rawGroups.add({...json, ...grupoConMiembros});
          }
        }
      } else {
        // Modo normal: cargar créditos propios
        rawCredits = await _creditService.getFullCreditsData(widget.nombreUsuario);
        rawGroups = await _savingsService.getGruposConMiembros(widget.nombreUsuario);
      }

      final List<dynamic> processedCredits = [];

      for (var c in rawCredits) {
        final cliente = c['Clientes'];
        final creditId = c['id'].toString();
        final bool esPagoUnico = c['tipo_credito'] == 'unico';

        // Extraer datos de la respuesta anidada (YA NO SON CONSULTAS APARTE)
        final List<dynamic> rawCuotas = c['Cuotas'] ?? [];
        final List<dynamic> rawPagos = c['Pagos'] ?? [];

        // Identificar la última renovación usando timestamp completo (con hora) para
        // que abonos del mismo día pero ANTES de la renovación se excluyan correctamente.
        final List<dynamic> renovaciones = c['Renovaciones'] ?? [];
        DateTime? ultimaRenovacion;
        if (renovaciones.isNotEmpty) {
          final sortedRenov = List<dynamic>.from(renovaciones);
          sortedRenov.sort((a, b) {
            final dateA = DateUt.parseFullDateTime(a['created_at'] ?? a['fecha_renovacion']);
            final dateB = DateUt.parseFullDateTime(b['created_at'] ?? b['fecha_renovacion']);
            return dateB.compareTo(dateA);
          });
          final last = sortedRenov.first;
          // Guardar el timestamp completo (con hora) de la última renovación
          ultimaRenovacion = DateUt.parseFullDateTime(last['created_at'] ?? last['fecha_renovacion']);
        }

        final List<CuotaPersonalizada> cuotas = rawCuotas
            .where((cq) {
              if (esPagoUnico) return true;
              if (ultimaRenovacion != null && cq['created_at'] != null) {
                final created = DateUt.parseFullDateTime(cq['created_at']);
                if (created.isBefore(ultimaRenovacion)) return false;
              }
              return true;
            })
            .map((cq) => CuotaPersonalizada(
                  numeroCuota: cq['numero_cuota'],
                  fechaPago: DateUt.parsePureDate(cq['fecha_pago']),
                  monto: (cq['monto'] as num).toDouble(),
                  pagada: cq['pagada'] ?? false,
                ))
            .toList();

        // Ordenar cuotas por número (menor a mayor)
        cuotas.sort((a, b) => a.numeroCuota.compareTo(b.numeroCuota));

        double pagosExcluidosDeUI = 0.0;
        final List<Pago> pagos = rawPagos
            .map((p) => Pago(
                  id: p['id'].toString(),
                  creditoId: creditId,
                  numeroCuota: p['numero_cuota'],
                  // Usar fecha_pago_real con fallback a fecha_pago para precisión horaria
                  fechaPago: DateUt.parseFullDateTime(p['fecha_pago_real'] ?? p['fecha_pago']),
                  monto: (p['monto'] as num).toDouble(),
                  fechaPagoReal: DateUt.parseFullDateTime(p['fecha_pago_real'] ?? p['fecha_pago']),
                  estado: 'pagado',
                  metodoPago: p['metodo_pago'] ?? 'efectivo',
                  referencia: p['referencia'] ?? '',
                  observaciones: p['observaciones'] ?? '',
                ))
            .where((p) {
              // Excluir abonos de renovación (ya incorporados en el monto total de la renovación)
              if (p.referencia == 'Abono en Renovación') {
                pagosExcluidosDeUI += p.monto;
                return false;
              }
              
              // Excluir pagos anteriores a la última renovación.
              // Usamos comparación por timestamp exacto (con hora) para distinguir
              // abonos hechos el mismo día pero antes de renovar.
              if (ultimaRenovacion != null) {
                if (p.fechaPago.isBefore(ultimaRenovacion)) {
                  pagosExcluidosDeUI += p.monto;
                  return false;
                }
              }
              return true;
            })
            .toList();

        // Ordenar pagos por fecha de pago real
        pagos.sort((a, b) => (a.fechaPagoReal ?? a.fechaPago)
            .compareTo(b.fechaPagoReal ?? b.fechaPago));

        final double dbTotal = (c['costo_inversion'] + c['margen_ganancia']).toDouble();
        final double uiTotal = dbTotal;

        if (esPagoUnico) {
          processedCredits.add(CreditoUnico(
            id: c['id'],
            nombreCliente: cliente['nombre'],
            telefono: cliente['telefono'] ?? '',
            concepto: c['concepto'],
            montoTotal: uiTotal,
            fechaLimite:
                DateUt.parsePureDate(c['fecha_vencimiento'] ?? c['fecha_inicio']),
            fechaInicio: c['fecha_inicio'] != null ? DateUt.parsePureDate(c['fecha_inicio']) : null,
            tipoPago: TipoPagoUnico.unico,
            descripcion: c['concepto'],
            pagosRealizados: pagos,
            notas: c['notas'],
            numeroCredito: c['numero_credito'],
            estadoDB: c['estado'],
            permisoCompartido: c['permiso_compartido'],
          ));
        } else {
          processedCredits.add({
            'id': c['id'],
            'nombre': cliente['nombre'],
            'telefono': cliente['telefono'] ?? '',
            'montoCuota': cuotas.isNotEmpty ? cuotas[0].monto : 0.0,
            'totalPagado': pagos.fold<double>(0, (sum, p) => sum + p.monto),
            'totalCredito': uiTotal,
            'concepto': c['concepto'],
            'tipo': 'cuotas',
            'cuotas': cuotas,
            'pagos': pagos,
            'pagosParciales': <int, double>{},
            'modalidadPago': _getModalidadName(c['modalidad_pago']),
            'numeroCredito': c['numero_credito'],
            'notas': c['notas'],
            'estadoDB': c['estado'],
            'permiso_compartido': c['permiso_compartido'],
          });
        }
      }

      setState(() {
        _financiamientos = processedCredits;
        _grupos = rawGroups;
        _isLoading = false;
      });
      _actualizarEstados();
    } catch (e) {
      print(' Error cargando créditos optimizados: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getModalidadName(dynamic index) {
    if (index == null) return 'No especificada';
    final idx = index is int ? index : int.tryParse(index.toString()) ?? 0;
    switch (idx) {
      case 0: return 'Diario';
      case 1: return 'Semanal';
      case 2: return 'Quincenal';
      case 3: return 'Mensual';
      case 4: return 'Personalizado';
      default: return 'Desconocido';
    }
  }

  String _filtroEstado = 'hoy';
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();
  bool _ordenAscendente = true; // 👈 NUEVO: Estado del orden

  // Función para calcular el estado de créditos en cuotas
  String _calcularEstadoCreditoCuotas(Map<String, dynamic> financiamiento) {
    // Si la BD dice 'Fallido', respetar ese estado
    if (financiamiento['estadoDB'] == 'Fallido') {
      return 'Fallido';
    }

    final fechaActual = DateUt.nowUtc();

    final totalPagado = financiamiento['totalPagado'] as double;
    final totalCredito = financiamiento['totalCredito'] as double;

    if ((totalPagado - totalCredito).abs() < 0.01) {
      return 'Pagado';
    }

    final cuotas = financiamiento['cuotas'] as List<CuotaPersonalizada>;
    int cuotasVencidas = 0;
    int cuotasPagadas = 0;

    for (var cuota in cuotas) {
      final fechaCuota = DateTime(
        cuota.fechaPago.year,
        cuota.fechaPago.month,
        cuota.fechaPago.day,
      );

      final pagoCompleto = cuota.pagada;

      if (pagoCompleto) {
        cuotasPagadas++;
        continue;
      }

      if (fechaCuota.isBefore(fechaActual)) {
        cuotasVencidas++;
      }
    }

    if (cuotasVencidas > 0) {
      return 'Atrasado';
    } else if (cuotasPagadas == cuotas.length) {
      return 'Pagado';
    } else {
      return 'Al día';
    }
  }

  // Actualizar estados de todos los financiamientos
  void _actualizarEstados() {
    for (var financiamiento in _financiamientos) {
      if (financiamiento is Map<String, dynamic>) {
        financiamiento['estado'] = _calcularEstadoCreditoCuotas(financiamiento);
      }
      // CreditoUnico ya tiene su propio cálculo de estado
    }
  }

  List<dynamic> get _financiamientosFiltrados {
    _actualizarEstados();

    final filtered = _financiamientos.where((f) {
      String nombre = '';
      String telefono = '';
      String estado = '';

      if (f is Map<String, dynamic>) {
        nombre = f['nombre'] ?? '';
        telefono = f['telefono'] ?? '';
        estado = f['estado']?.toLowerCase() ?? '';
      } else if (f is CreditoUnico) {
        nombre = f.nombreCliente;
        telefono = f.telefono;
        estado = f.estado.toLowerCase();
      }

      final matchesBusqueda = _busqueda.isEmpty ||
          nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          telefono.contains(_busqueda);

      bool matchesEstado = true;
      if (_filtroEstado != 'todos') {
        if (_filtroEstado == 'hoy') {
          final hoy = DateTime.now();
          final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
          
          if (f is Map<String, dynamic>) {
            final cuotas = f['cuotas'] as List<CuotaPersonalizada>;
            final totalPagado = f['totalPagado'] as double;
            final totalCredito = f['totalCredito'] as double;
            
            // Si ya está pagado por completo, no sale en "Hoy"
            if ((totalPagado - totalCredito).abs() < 0.01) {
              matchesEstado = false;
            } else {
              // Buscar si alguna cuota pendiente es para hoy
              matchesEstado = cuotas.any((c) {
                final fechaCuota = DateTime(c.fechaPago.year, c.fechaPago.month, c.fechaPago.day);
                return !c.pagada && fechaCuota.isAtSameMomentAs(hoySinHora);
              });
            }
          } else if (f is CreditoUnico) {
            final fechaLimiteSinHora = DateTime(f.fechaLimite.year, f.fechaLimite.month, f.fechaLimite.day);
            matchesEstado = !f.estaPagado && fechaLimiteSinHora.isAtSameMomentAs(hoySinHora);
          }
        } else if (_filtroEstado == 'atrasado') {
          matchesEstado = estado == 'atrasado' || estado == 'vencido';
        } else {
          matchesEstado = estado == _filtroEstado.toLowerCase();
        }
      }

      return matchesBusqueda && matchesEstado;
    }).toList();

    // 🚀 NUEVO: Ordenar por número de crédito
    filtered.sort((a, b) {
      int numA = 0;
      int numB = 0;

      if (a is Map<String, dynamic>) {
        numA = a['numeroCredito'] ?? 0;
      } else if (a is CreditoUnico) {
        numA = a.numeroCredito ?? 0;
      }

      if (b is Map<String, dynamic>) {
        numB = b['numeroCredito'] ?? 0;
      } else if (b is CreditoUnico) {
        numB = b.numeroCredito ?? 0;
      }

      return _ordenAscendente ? numA.compareTo(numB) : numB.compareTo(numA);
    });

    return filtered;
  }

  Color _getColorParaFiltro(String filtro) {
    switch (filtro.toLowerCase()) {
      case 'todos':
        return AppColors.info;
      case 'hoy':
        return AppColors.warning;
      case 'al día':
        return AppColors.primaryGreen;
      case 'atrasado':
        return AppColors.error;
      case 'pagado':
        return AppColors.success;
      case 'fallido':
        return const Color(0xFF37474F);
      default:
        return AppColors.mediumGrey;
    }
  }



  double getMontoRestanteCuota(int financiamientoIndex, int numeroCuota) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final cuota = (f['cuotas'] as List).firstWhere(
        (c) => c.numeroCuota == numeroCuota,
      );

      if (cuota.pagada) return 0.0;

      return cuota.monto;
    }
    return 0.0;
  }

  bool esCuotaParcialmentePagada(int financiamientoIndex, int numeroCuota) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final cuota = (f['cuotas'] as List).firstWhere(
        (c) => c.numeroCuota == numeroCuota,
      );

      // En nuestra lógica actual, si no está pagada pero el monto es menor al original, es parcial.
      // Sin embargo, como el monto en DB es el saldo, necesitamos saber el monto original para estar seguros.
      // Por ahora, una forma simple es verificar si hay pagos registrados para esta cuota pero aún no está marcada como pagada.
      final pagos = f['pagos'] as List<Pago>;
      final tienePagos = pagos.any((p) => p.numeroCuota == numeroCuota);

      return tienePagos && !cuota.pagada;
    }
    return false;
  }

  int getCuotasVencidas(int financiamientoIndex) {
    final f = _financiamientos[financiamientoIndex];
    if (f is Map<String, dynamic>) {
      final hoy = DateTime.now();
      final fechaActual = DateTime(hoy.year, hoy.month, hoy.day);

      final cuotas = f['cuotas'] as List<CuotaPersonalizada>;
      int vencidas = 0;

      for (var cuota in cuotas) {
        final fechaCuota = DateTime(
          cuota.fechaPago.year,
          cuota.fechaPago.month,
          cuota.fechaPago.day,
        );

        final pagada = cuota.pagada;

        if (!pagada && fechaCuota.isBefore(fechaActual)) {
          vencidas++;
        }
      }

      return vencidas;
    }
    return 0;
  }

  bool _tienePermiso(String? permiso, {bool requiereSupervisor = false}) {
    // 1. Si el rol global es admin, tiene acceso total
    if (widget.rol == 'admin') return true;
    
    // 2. Determinar el nivel efectivo (el mayor entre su rol global y el permiso asignado)
    // Esto protege en caso de que un supervisor reciba un crédito con etiqueta de 'empleado'
    final String nivel = (widget.rol == 'supervisor' || permiso == 'supervisor' || permiso == 'total') 
        ? 'supervisor' 
        : (widget.rol == 'empleado' || permiso == 'empleado' || permiso == 'cobro') 
            ? 'empleado' 
            : permiso ?? 'lectura';

    if (nivel == 'supervisor') return true;
    if (requiereSupervisor) return false;
    
    // Si solo requiere nivel empleado (Abonar, Crear, Renovar)
    return nivel == 'empleado';
  }

  Future<void> _pagarCuotaCompleto(
    int financiamientoIndex,
    int numeroCuota,
    double monto,
    DateTime fechaPago,
    String metodoPago,
    String referencia,
    String observaciones,
    bool aplicarMora,
    double? montoMora,
    bool esPagoParcial,
    String? comprobantePath, // 👈 NUEVO
  ) async {
    final f = _financiamientos[financiamientoIndex];
    // Soporte tanto para Map como para CreditoUnico
    
    // VALIDACIÓN DE PERMISOS
    final String? permiso = (f is Map) ? f['permiso_compartido'] : (f as CreditoUnico).permisoCompartido;
    if (widget.modoTrabajador && !_tienePermiso(permiso)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Permiso denegado: Funciones de lectura no permiten registrar pagos.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // 1. Guardar en base de datos
      await _creditService.savePayment(
        creditId: f['id'].toString(),
        numeroCuota: numeroCuota,
        montoPagado: monto,
        fechaPago: fechaPago,
        metodoPago: metodoPago,
        referencia: referencia,
        observaciones: observaciones,
        esPagoParcial: esPagoParcial,
        comprobantePath: comprobantePath,
        rolUsuario: widget.rol,
        adminNombre: _adminNombre ?? widget.nombreUsuario,
      );

      // 2. Registrar en bitácora
      final String nombreCliente = (f is Map) ? f['nombre'] : (f as CreditoUnico).nombreCliente;
      final String numCredito = (f is Map) 
          ? (f['numeroCredito']?.toString() ?? 'S/N') 
          : ((f as CreditoUnico).numeroCredito?.toString() ?? 'S/N');

      await BitacoraService().registrarActividad(
        usuarioNombre: widget.nombreUsuario,
        accion: 'pago_cuota',
        descripcion: 'Registró pago de cuota #$numeroCuota (Crédito #$numCredito) para $nombreCliente',
        entidadTipo: 'credito',
        entidadId: (f is Map) ? f['id'].toString() : (f as CreditoUnico).id,
      );

      // 3. Refrescar datos desde la base de datos
      await _loadData();

      // Diferenciar mensaje según rol
      final bool esEmpleado = widget.rol == 'empleado';
      String mensaje;
      Color colorMensaje;

      if (esEmpleado) {
        mensaje = '🕒 Pago de cuota #$numeroCuota registrado. En espera de aprobación.';
        colorMensaje = Colors.orange;
      } else {
        mensaje = esPagoParcial
            ? '✅ Pago parcial de cuota #$numeroCuota registrado'
            : '✅ Pago de cuota #$numeroCuota registrado';
        colorMensaje = AppColors.success;
        if (aplicarMora && montoMora != null && montoMora > 0) {
          mensaje += ' (incluye mora de \$${montoMora.toStringAsFixed(2)})';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: colorMensaje,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pagarCreditoUnico(CreditoUnico credito, Pago pago) async {
    if (widget.modoTrabajador && !_tienePermiso(credito.permisoCompartido)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Permiso denegado: Funciones de lectura no permiten registrar pagos.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // 1. Guardar en base de datos
      await _creditService.savePayment(
        creditId: credito.id,
        numeroCuota: 1, // Créditos únicos siempre usan la cuota 1
        montoPagado: pago.monto,
        fechaPago: pago.fechaPagoReal ?? DateTime.now(), // 👈 CORRECCIÓN: Usar la fecha REAL elegida
        metodoPago: pago.metodoPago ?? 'efectivo',
        referencia: pago.referencia ?? '',
        observaciones: pago.observaciones ?? '',
        esPagoParcial: pago.monto < credito.saldoPendiente,
        rolUsuario: widget.rol,
        adminNombre: _adminNombre ?? widget.nombreUsuario,
      );

      // 2. Registrar en bitácora
      final String numCredito = credito.numeroCredito?.toString() ?? 'S/N';
      await BitacoraService().registrarActividad(
        usuarioNombre: widget.nombreUsuario,
        accion: 'pago_credito_unico',
        descripcion: 'Registró pago de \$${pago.monto.toStringAsFixed(2)} para ${credito.nombreCliente} (Crédito #$numCredito)',
        entidadTipo: 'credito',
        entidadId: credito.id,
      );

      // 3. Refrescar datos
      await _loadData();

      if (mounted) {
        final bool esEmpleado = widget.rol == 'empleado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEmpleado
                ? '🕒 Pago de \$${pago.monto.toStringAsFixed(2)} registrado. En espera de aprobación.'
                : '✅ Pago de \$${pago.monto.toStringAsFixed(2)} registrado'),
            backgroundColor: esEmpleado ? Colors.orange : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildFiltros() {
    final filtros = ['hoy', 'atrasado', 'al día', 'pagado', 'fallido', 'todos'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...filtros.map((filtro) {
            final isSelected = _filtroEstado == filtro;
            final color = _getColorParaFiltro(filtro);

            String nombreFiltro = filtro;
            if (filtro == 'todos') nombreFiltro = 'Todos';
            else if (filtro == 'hoy') nombreFiltro = 'Hoy';
            else if (filtro == 'atrasado') nombreFiltro = 'Vencidos';
            else if (filtro == 'al día') nombreFiltro = 'Al día';
            else if (filtro == 'pagado') nombreFiltro = 'Pagados';
            else if (filtro == 'fallido') nombreFiltro = 'Fallido';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  nombreFiltro,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selectedColor: color,
                checkmarkColor: Colors.white,
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : color.withOpacity(0.5),
                ),
                onSelected: (selected) {
                  setState(() {
                    _filtroEstado = filtro;
                  });
                },
              ),
            );
          }).toList(),
          
          // 🚀 NUEVO: Botón de Ordenamiento
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ActionChip(
              avatar: Icon(
                _ordenAscendente ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                _ordenAscendente ? 'Menor a Mayor' : 'Mayor a Menor',
                style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
              ),
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              onPressed: () {
                setState(() {
                  _ordenAscendente = !_ordenAscendente;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCredito(dynamic creditId, String nombreCliente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 8),
            const Text('Eliminar crédito'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el crédito de $nombreCliente?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _creditService.deleteCredit(creditId.toString());
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Crédito de $nombreCliente eliminado'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cambiarFallido(dynamic creditId, String nombreCliente, String estadoActual) async {
    final yaEsFallido = estadoActual == 'Fallido';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              yaEsFallido ? Icons.restore : Icons.block,
              color: yaEsFallido ? AppColors.primaryGreen : const Color(0xFF37474F),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                yaEsFallido ? 'Quitar de Fallido' : 'Marcar como Fallido',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          yaEsFallido
              ? '¿Quieres quitar el crédito de $nombreCliente de Fallido?'
              : '¿Estás seguro de que deseas marcar el crédito de $nombreCliente como Fallido?\n\nCada abono que reciba contará como ganancia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: yaEsFallido ? AppColors.primaryGreen : const Color(0xFF37474F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(yaEsFallido ? 'Quitar' : 'Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final nuevoEstado = yaEsFallido ? 'Activo' : 'Fallido';
        await _creditService.updateCreditEstado(creditId.toString(), nuevoEstado);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                yaEsFallido
                    ? '✅ Crédito de $nombreCliente removido de Fallido'
                    : '⚫ Crédito de $nombreCliente marcado como Fallido',
              ),
              backgroundColor: yaEsFallido ? AppColors.success : const Color(0xFF37474F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                correo: widget.correo,
                userName: widget.nombreUsuario,
                rol: widget.rol,
              ),
            ),
            (route) => false,
          );
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: CustomDrawer(
            nombre_usuario: widget.nombreUsuario,
            ventanaActiva: widget.modoTrabajador ? 'trabajador' : 'Cuotas Personales',
            rol: widget.rol,
            correo: widget.correo,
          ),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.modoTrabajador ? 'Panel de Trabajo' : 'Seguimiento de Cuotas',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.modoTrabajador && (widget.rol == 'supervisor' || widget.rol == 'empleado'))
                  Text(
                    widget.rol == 'supervisor' ? 'Rol: Supervisor' : 'Rol: Empleado',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                  ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o teléfono...',
                        hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _busqueda = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: [
                      Tab(text: 'Cuota Simple'),
                      Tab(text: 'Cuota Fija'),
                      Tab(text: 'Grupos'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildListado(TipoCredito.unPago),
              _buildListado(TipoCredito.cuotas),
              _buildListado(TipoCredito.grupal),
            ],
          ),
          floatingActionButton: (widget.modoTrabajador && widget.rol == 'cliente')
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreditoPage(
                                nombreUsuario: _adminNombre ?? widget.nombreUsuario,
                                esModoTrabajo: widget.modoTrabajador,
                                rolActual: widget.rol,
                              )),
                    ).then((_) => _loadData());
                  },
                  tooltip: 'Nuevo crédito',
                  child: const Icon(Icons.add),
                ),
        ),
      ),
    );
  }

  Widget _buildListado(TipoCredito tipo) {
    final List<dynamic> source = (tipo == TipoCredito.grupal) 
        ? _grupos 
        : _financiamientosFiltrados;

    final filteredItems = source.where((f) {
      if (tipo == TipoCredito.unPago) return f is CreditoUnico;
      if (tipo == TipoCredito.cuotas) return f is Map<String, dynamic> && f['tipo'] != 'grupal';
      if (tipo == TipoCredito.grupal) return f is Map<String, dynamic>;
      return false;
    }).toList();

    return Column(
      children: [
        _buildFiltros(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tipo == TipoCredito.grupal ? Icons.group_off : Icons.search_off,
                            size: 64,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tipo == TipoCredito.grupal 
                              ? 'Aún no tienes grupos creados' 
                              : 'No hay registros para este tipo',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadData(),
                      color: AppColors.primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final originalIndex = _financiamientos.indexOf(item);
                          return _buildTarjetaItem(item, originalIndex);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTarjetaItem(dynamic item, int originalIndex) {
    if (item is Map<String, dynamic> && item.containsKey('cantidad_participantes')) {
      final grupo = GrupoAhorro.fromJson(item);
      final rawMiembros = item['Miembros_Grupo'] as List? ?? [];
      final miembros = rawMiembros.map((m) => MiembroGrupo.fromJson(m)).toList();

      return TarjetaGrupo(
        grupo: grupo,
        miembros: miembros,
        onVerDetalle: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrupoDashboardPage(
                grupoId: grupo.id!,
                usuarioNombre: widget.nombreUsuario,
              ),
            ),
          ).then((_) => _loadData());
        },
      );
    }
    
    if (item is CreditoUnico) {
      return TarjetaCreditoUnico(
        credito: item,
        onPagoRealizado: (pago) => _pagarCreditoUnico(item, pago),
        onEditar: (widget.modoTrabajador && !_tienePermiso(item.permisoCompartido, requiereSupervisor: true)) ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreditoPage(
                nombreUsuario: widget.nombreUsuario,
                creditoIdEditar: item.id.toString(),
                esModoTrabajo: widget.modoTrabajador,
                rolActual: widget.rol,
              ),
            ),
          ).then((_) => _loadData());
        },
        onEliminar: (widget.modoTrabajador && !_tienePermiso(item.permisoCompartido, requiereSupervisor: true)) ? null : () => _eliminarCredito(
          item.id,
          item.nombreCliente,
        ),
        onFallido: (widget.modoTrabajador && !_tienePermiso(item.permisoCompartido, requiereSupervisor: true)) ? null : () => _cambiarFallido(
          item.id,
          item.nombreCliente,
          item.estadoDB ?? '',
        ),
        onVerDetalle: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleCreditoPage(
                creditoId: item.id.toString(),
                nombreUsuario: widget.nombreUsuario,
                rol: widget.rol,
                onEditar: (widget.modoTrabajador && !_tienePermiso(item.permisoCompartido, requiereSupervisor: true)) ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreditoPage(
                        nombreUsuario: widget.nombreUsuario,
                        creditoIdEditar: item.id.toString(),
                        esModoTrabajo: widget.modoTrabajador,
                        rolActual: widget.rol,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                onEliminar: (widget.modoTrabajador && !_tienePermiso(item.permisoCompartido, requiereSupervisor: true)) ? null : () => _eliminarCredito(
                  item.id,
                  item.nombreCliente,
                ),
                modoTrabajador: widget.modoTrabajador,
                permisoCompartido: item.permisoCompartido,
              ),
            ),
          );
        },
      );
    } else if (item is Map<String, dynamic>) {
      final totalCuotas = item['cuotas'].length;
      final cuotasPagadas = item['pagos'].length;
      final cuotasVencidas = getCuotasVencidas(originalIndex);

      return TarjetaFinanciamiento(
        creditoId: item['id']?.toString(),
        nombreCliente: item['nombre'],
        modalidadPago: item['modalidadPago'] ?? 'En Cuotas',
        telefono: item['telefono'],
        estado: item['estado'] ?? 'Pendiente',
        montoCuota: item['montoCuota'],
        totalPagado: item['totalPagado'],
        totalPendiente: item['totalPendiente'] ?? (item['totalCredito'] - item['totalPagado']),
        progreso: item['progreso'] ?? (item['totalPagado'] / item['totalCredito']),
        cuotas: item['cuotas'],
        pagos: item['pagos'],
        cuotasVencidas: cuotasVencidas,
        concepto: item['concepto'] ?? 'Sin concepto',
        totalCredito: item['totalCredito'] ?? 0.0,
        numeroCredito: item['numeroCredito'],
        notas: item['notas'],
        estadoDB: item['estadoDB'],
        onFallido: (widget.modoTrabajador && !_tienePermiso(item['permiso_compartido'], requiereSupervisor: true)) ? null : () => _cambiarFallido(
          item['id'],
          item['nombre'],
          item['estadoDB'] ?? '',
        ),
        onVerDetalle: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleCreditoPage(
                creditoId: item['id'].toString(),
                nombreUsuario: widget.nombreUsuario,
                rol: widget.rol,
                onEditar: (widget.modoTrabajador && !_tienePermiso(item['permiso_compartido'], requiereSupervisor: true)) ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreditoPage(
                        nombreUsuario: widget.nombreUsuario,
                        creditoIdEditar: item['id'].toString(),
                        esModoTrabajo: widget.modoTrabajador,
                        rolActual: widget.rol,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                onEliminar: (widget.modoTrabajador && !_tienePermiso(item['permiso_compartido'], requiereSupervisor: true)) ? null : () => _eliminarCredito(
                  item['id'],
                  item['nombre'],
                ),
                modoTrabajador: widget.modoTrabajador,
                permisoCompartido: item['permiso_compartido'],
              ),
            ),
          );
        },
        onEditar: (widget.modoTrabajador && !_tienePermiso(item['permiso_compartido'], requiereSupervisor: true)) ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreditoPage(
                nombreUsuario: widget.nombreUsuario,
                creditoIdEditar: item['id'].toString(),
                esModoTrabajo: widget.modoTrabajador,
                rolActual: widget.rol,
              ),
            ),
          ).then((_) => _loadData());
        },
        onEliminar: (widget.modoTrabajador && !_tienePermiso(item['permiso_compartido'], requiereSupervisor: true)) ? null : () => _eliminarCredito(
          item['id'],
          item['nombre'],
        ),
        onCuotaTap: (numeroCuota) {
          final cuota = (item['cuotas'] as List).firstWhere(
            (c) => c.numeroCuota == numeroCuota,
          );

          final montoRestante = getMontoRestanteCuota(
            originalIndex,
            numeroCuota,
          );

          if (montoRestante <= 0) return;

          final esPagoParcialPrevio = esCuotaParcialmentePagada(
            originalIndex,
            numeroCuota,
          );

          showDialog(
            context: context,
            builder: (context) => DialogoPagoCuotaCompleto(
              numeroCuota: numeroCuota,
              monto: cuota.monto,
              montoRestante: montoRestante,
              fechaVencimiento: cuota.fechaPago,
              nombreCliente: item['nombre'],
              concepto: item['concepto'] ?? 'Préstamo',
              montoPagadoHastaAhora: item['totalPagado'],
              totalCredito: item['totalCredito'] ?? 500.00,
              totalCuotas: totalCuotas,
              cuotasPagadas: cuotasPagadas,
              esPagoParcial: esPagoParcialPrevio,
              onPagar: (
                monto,
                fechaPago,
                metodoPago,
                referencia,
                observaciones,
                aplicarMora,
                montoMora,
                esPagoParcial,
                comprobantePath,
              ) {
                _pagarCuotaCompleto(
                  originalIndex,
                  numeroCuota,
                  monto,
                  fechaPago,
                  metodoPago,
                  referencia,
                  observaciones,
                  aplicarMora,
                  montoMora,
                  esPagoParcial,
                  comprobantePath,
                );
              },
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }
}
