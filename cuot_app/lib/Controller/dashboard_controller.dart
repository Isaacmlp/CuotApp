import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier {
  final CreditService _creditService = CreditService();
  String? userName;

  // 🔴 AQUÍ SE ALMACENARÁN LOS DATOS DEL DASHBOARD
  int totalCredits = 0; // 1. Cantidad de Créditos
  double totalPaid = 0.0; // 2. Dinero abonado
  int pendingWeeklyQuotas = 0; // 3. Cuotas pendientes por semana
  double pendingBalance = 0.0; // 4. Saldo de Cuotas Pendiente
  List<PaymentModel> upcomingPayments = []; // 5. Próximos Vencimientos
  List<PaymentModel> latePayments = []; // 6. Cuotas Atrasadas
  double totalCapital = 0.0; // 7. Capital total
  double gananciaPorCobrar = 0.0; // 8. Ganancia total por cobrar (mes actual)
  double gananciaMensual = 0.0; // 9. Ganancia cobrada del mes actual

  bool isLoading = true;
  String? errorMessage;

  DashboardController({String? userName, String? correo}) {
    this.userName = userName;
    loadDashboardData();
  }

  // 🔴 MÉTODO PRINCIPAL OPTIMIZADO: Carga todo en una sola consulta
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 🚀 Una sola consulta para traer todo lo relacionado al usuario
      final creditsData =
          await _creditService.getFullCreditsData(
            userName ?? '',
            forceRefresh: forceRefresh,
          );

      _processData(creditsData);
    } catch (e) {
      print('Error en loadDashboardData: $e');
      errorMessage = 'Error al cargar datos: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _processData(List<Map<String, dynamic>> credits) {
    final now = DateTime.now();

    // Configurar rangos de fechas (mismos que en CreditService original)
    final inicioSemana = now.subtract(Duration(days: now.weekday - 1)).copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final finSemana = inicioSemana.add(const Duration(days: 7));
    final sevenDaysLater = now.add(const Duration(days: 7));
    final lateThreshold = now.subtract(const Duration(hours: 24));

    // Reiniciar contadores
    totalCredits = 0;
    totalPaid = 0.0;
    pendingWeeklyQuotas = 0;
    pendingBalance = 0.0;
    upcomingPayments = [];
    latePayments = [];
    totalCapital = 0.0;
    gananciaPorCobrar = 0.0;
    gananciaMensual = 0.0;

    for (var credit in credits) {
      // Identificar última renovación para aislar pagos/cuotas del ciclo actual
      final List<dynamic> renovaciones = credit['Renovaciones'] ?? [];
      DateTime? ultimaRenovacion;
      if (renovaciones.isNotEmpty) {
        final sortedRenov = List<dynamic>.from(renovaciones);
        sortedRenov.sort((a, b) {
          final dateA = DateUt.parseFullDateTime(a['created_at'] ?? a['fecha_renovacion']);
          final dateB = DateUt.parseFullDateTime(b['created_at'] ?? b['fecha_renovacion']);
          return dateB.compareTo(dateA);
        });
        ultimaRenovacion = DateUt.parseFullDateTime(
          sortedRenov.first['created_at'] ?? sortedRenov.first['fecha_renovacion']
        );
      }

      // 1. Créditos activos
      if (credit['estado'] != 'Pagado') {
        totalCredits++;
      }

      // 7. Capital total
      if (credit['estado'] != 'Pagado') {
        totalCapital += (credit['costo_inversion'] as num).toDouble();
      }

      final clienteData = credit['Clientes'];
      final clienteNombre =
          clienteData != null ? clienteData['nombre'] : 'Cliente';
      final concepto = credit['concepto'] ?? 'Crédito';
      final creditId = credit['id'].toString();

      // 2. Dinero abonado (Solo pagos del ciclo actual)
      final List<dynamic> pagosRaw = credit['Pagos'] ?? [];
      for (var p in pagosRaw) {
        final ref = p['referencia']?.toString() ?? '';
        if (ref == 'Abono en Renovación') continue;

        final fechaStr = p['fecha_pago_real'] ?? p['fecha_pago'];
        final fechaPago = DateUt.parseFullDateTime(fechaStr);

        // Si hay renovación, ignorar pagos anteriores al timestamp exacto de la misma
        if (ultimaRenovacion != null && fechaPago.isBefore(ultimaRenovacion)) {
          continue;
        }

        totalPaid += (p['monto'] as num).toDouble();
      }

      // 3, 4, 5, 6. Analizar cuotas (Solo cuotas del ciclo actual)
      final List<dynamic> cuotasRaw = credit['Cuotas'] ?? [];
      for (var c in cuotasRaw) {
        // Filtrar cuotas históricas si hay renovación (importante para saldo pendiente)
        if (ultimaRenovacion != null && c['created_at'] != null) {
          final created = DateUt.parseFullDateTime(c['created_at']);
          if (created.isBefore(ultimaRenovacion)) continue;
        }

        final double monto = (c['monto'] as num).toDouble();
        final bool pagada = c['pagada'] ?? false;
        final DateTime fechaPago = DateTime.parse(c['fecha_pago']);

        if (!pagada) {
          // 4. Saldo pendiente
          pendingBalance += monto;

          // 3. Cuotas de la semana actual
          if (fechaPago.isAfter(inicioSemana) &&
              fechaPago.isBefore(finSemana)) {
            pendingWeeklyQuotas++;
          }

          // 5. Próximos vencimientos (incluyendo hoy hasta los próximos 7 días)
          final hoyMedianoche = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
          if (!fechaPago.isBefore(hoyMedianoche) && fechaPago.isBefore(sevenDaysLater)) {
            upcomingPayments.add(PaymentModel(
              id: c['id'].toString(),
              creditId: creditId,
              amount: monto,
              date: fechaPago,
              installmentNumber: c['numero_cuota'] as int,
              status: 'pending',
              clientName: clienteNombre,
              concept: concepto,
            ));
          }

          // 6. Cuotas atrasadas
          if (fechaPago.isBefore(lateThreshold)) {
            latePayments.add(PaymentModel(
              id: c['id'].toString(),
              creditId: creditId,
              amount: monto,
              date: fechaPago,
              installmentNumber: c['numero_cuota'] as int,
              status: 'late',
              clientName: clienteNombre,
              concept: concepto,
            ));
          }
        }
      }

      // ===== CÁLCULO DE GANANCIAS =====
      final List<dynamic> renovacionesCredito = credit['Renovaciones'] ?? [];
      final double margen = (credit['margen_ganancia'] as num).toDouble();
      final double costoInv = (credit['costo_inversion'] as num).toDouble();
      final double totalCredito = costoInv + margen;
      final bool esListaNegra = credit['estado'] == 'Lista Negra';

      // Ratio de ganancia: qué porcentaje de cada pago es ganancia
      // Lista Negra: todo pago es 100% ganancia
      final double profitRatio = esListaNegra
          ? 1.0
          : (totalCredito > 0 ? margen / totalCredito : 0.0);

      // Ganancia proporcional de cada pago del ciclo actual (Para Ganancia Mensual)
      double pagadoTotal = 0.0;
      for (var p in pagosRaw) {
        final ref = p['referencia']?.toString() ?? '';
        if (ref == 'Abono en Renovación') continue;

        final fechaStr = p['fecha_pago_real'] ?? p['fecha_pago'];
        final fechaPago = DateUt.parseFullDateTime(fechaStr);

        if (ultimaRenovacion != null && fechaPago.isBefore(ultimaRenovacion)) {
          continue;
        }

        final double montoPago = (p['monto'] as num).toDouble();
        pagadoTotal += montoPago;
        
        // Ganancia mensual: solo pagos del mes actual
        if (fechaPago.year == now.year && fechaPago.month == now.month) {
          gananciaMensual += montoPago * profitRatio;
        }
      }

      // Ganancia adicional por renovaciones (solo para Ganancia Mensual)
      for (var renov in renovacionesCredito) {
        final String estadoRenov = renov['estado'] ?? '';
        if (estadoRenov != 'aprobada') continue;

        final double abono = (renov['monto_abono'] as num?)?.toDouble() ?? 0.0;
        if (abono <= 0) continue;

        final fechaRenov = DateUt.parseFullDateTime(
          renov['created_at'] ?? renov['fecha_renovacion'],
        );
        if (fechaRenov.year == now.year && fechaRenov.month == now.month) {
          gananciaMensual += abono;
        }
      }

      // Ganancia por Cobrar (este mes)
      if (credit['estado'] != 'Pagado') {
        final String modalidad = credit['modalidad_pago'] ?? '';
        final bool esPagoUnico = modalidad.toLowerCase() == 'unico' || modalidad.toLowerCase() == 'único';

        if (esPagoUnico) {
          final fechaVencimientoStr = credit['fecha_vencimiento'] ?? credit['fecha_inicio'];
          if (fechaVencimientoStr != null) {
            final fechaVencimiento = DateUt.parsePureDate(fechaVencimientoStr);
            if (fechaVencimiento.year == now.year && fechaVencimiento.month == now.month) {
              final double pendiente = totalCredito - pagadoTotal;
              if (pendiente > 0) {
                gananciaPorCobrar += pendiente * profitRatio;
              }
            }
          }
        } else {
          // Cuotas
          for (var c in cuotasRaw) {
            if (ultimaRenovacion != null && c['created_at'] != null) {
              final created = DateUt.parseFullDateTime(c['created_at']);
              if (created.isBefore(ultimaRenovacion)) continue;
            }
            final bool pagada = c['pagada'] ?? false;
            final String? fechaPagoStr = c['fecha_pago'];
            if (fechaPagoStr == null) continue;
            
            final fechaCuota = DateUt.parsePureDate(fechaPagoStr);
            if (fechaCuota.year == now.year && fechaCuota.month == now.month) {
               if (!pagada) {
                 final double montoCuota = (c['monto'] as num).toDouble();
                 final int numCuota = c['numero_cuota'];
                 double pagadoCuota = 0.0;
                 for (var p in pagosRaw) {
                   if (p['numero_cuota'] == numCuota) {
                      pagadoCuota += (p['monto'] as num).toDouble();
                   }
                 }
                 final double pendienteCuota = montoCuota - pagadoCuota;
                 if (pendienteCuota > 0) {
                   gananciaPorCobrar += pendienteCuota * profitRatio;
                 }
               }
            }
          }
        }
      }
    }

   

    // Ordenar listas por fecha
    upcomingPayments.sort((a, b) => a.date.compareTo(b.date));
    latePayments.sort((a, b) => a.date.compareTo(b.date));
  }

  // Método para refrescar manualmente (pull-to-refresh)
  Future<void> refreshData() async {
    await loadDashboardData(forceRefresh: true);
  }

  String getName() {
    return userName ?? 'Usuario indefinido';
  }

  String getFirstName() {
    final name = userName ?? 'Usuario';
    return name.split(' ').first;
  }
}
