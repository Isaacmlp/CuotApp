import 'package:cuot_app/Model/payment_model.dart';

class CreditModel {
  final String id;
  final String clientName;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final int totalInstallments;
  final int paidInstallments;
  final DateTime startDate;
  final DateTime nextDueDate;
  final List<PaymentModel> payments;
  final String status; // 'active', 'late', 'completed'

  CreditModel({
    required this.id,
    required this.clientName,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.startDate,
    required this.nextDueDate,
    required this.payments,
    required this.status,
  });

  // Calcular cuotas pendientes
  int get pendingInstallments => totalInstallments - paidInstallments;
  
  // Calcular saldo de cuotas pendiente
  double get pendingInstallmentsAmount => pendingAmount;
  
  // Verificar si está atrasado
  bool get isLate => status == 'late';
  
  // Cuota actual (siguiente a pagar)
  int get currentInstallment => paidInstallments + 1;

  // Factory constructor desde JSON (para Supabase)
  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json['id'].toString(),
      clientName: json['client_name'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      totalInstallments: json['total_installments'] ?? 0,
      paidInstallments: json['paid_installments'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      nextDueDate: DateTime.parse(json['next_due_date']),
      payments: (json['payments'] as List? ?? [])
          .map((p) => PaymentModel.fromJson(p))
          .toList(),
      status: json['status'] ?? 'active',
    );
  }
}