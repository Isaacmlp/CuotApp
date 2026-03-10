import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:flutter/material.dart';


class DashboardController extends ChangeNotifier {
  final CreditService _creditService = CreditService();
  String? userName;
  
  // 🔴 AQUÍ SE ALMACENARÁN LOS DATOS DEL DASHBOARD
  int totalCredits = 0;              // 1. Cantidad de Créditos
  double totalPaid = 0.0;            // 2. Dinero abonado
  int pendingWeeklyQuotas = 0;       // 3. Cuotas pendientes por semana
  double pendingBalance = 0.0;       // 4. Saldo de Cuotas Pendiente
  List<PaymentModel> upcomingPayments = []; // 5. Próximos Vencimientos
  List<PaymentModel> latePayments = [];     // 6. Cuotas Atrasadas
  
  bool isLoading = true;
  String? errorMessage;

  DashboardController({String? userName, String? correo})  {
    this.userName = userName;
    loadDashboardData();
  }

  // 🔴 MÉTODO PRINCIPAL: CARGA TODOS LOS DATOS DEL DASHBOARD
  Future<void> loadDashboardData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Cargar todos los datos en paralelo para mejor rendimiento
      await Future.wait([
        _loadTotalCredits(),
        _loadTotalPaid(),
        _loadPendingWeeklyQuotas(),
        _loadPendingBalance(),
        _loadUpcomingPayments(),
        _loadLatePayments(),
      ]);
    } catch (e) {
      errorMessage = 'Error al cargar datos: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔴 IMPLEMENTA CADA MÉTODO CON SU LÓGICA ESPECÍFICA
  
  Future<void> _loadTotalCredits() async {
    totalCredits = await _creditService.getTotalCredits();
  }

  Future<void> _loadTotalPaid() async {
    totalPaid = await _creditService.getTotalPaidAmount();
  }

  Future<void> _loadPendingWeeklyQuotas() async {
    final weeklyData = await _creditService.getPendingInstallmentsByWeek();
    // Sumar todas las cuotas de la semana actual
    pendingWeeklyQuotas = weeklyData.values.fold(0, (sum, item) => sum + item);
  }

  Future<void> _loadPendingBalance() async {
    pendingBalance = await _creditService.getTotalPendingAmount();
  }

  Future<void> _loadUpcomingPayments() async {
    upcomingPayments = await _creditService.getUpcomingPayments();
  }

  Future<void> _loadLatePayments() async {
    latePayments = await _creditService.getLatePayments();
  }

  // Método para refrescar manualmente
  Future<void> refreshData() async {
    await loadDashboardData();
  }

  String getName() {
    return userName ?? 'Usuario indefinido';
  }
}