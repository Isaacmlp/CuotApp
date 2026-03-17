import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverduePayments extends StatelessWidget {
  final List<PaymentModel> payments;  // 6. Cuotas Atrasadas

  const OverduePayments({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Agrupar cuotas por cliente
    final Map<String, List<PaymentModel>> groupedByClient = {};
    for (var p in payments) {
      final key = p.clientName ?? 'Cliente Desconocido';
      if (!groupedByClient.containsKey(key)) {
        groupedByClient[key] = [];
      }
      groupedByClient[key]!.add(p);
    }

    final clientNames = groupedByClient.keys.toList();

    return Card(
      color: AppColors.error.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                const Text(
                  'Cuotas Vencidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${payments.length}',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clientNames.length > 5 ? 5 : clientNames.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final clientName = clientNames[index];
                final clientPayments = groupedByClient[clientName]!;
                final totalAmount = clientPayments.fold(0.0, (sum, p) => sum + p.amount);
                final oldestDate = clientPayments.map((p) => p.date).reduce((a, b) => a.isBefore(b) ? a : b);
                final daysLate = DateTime.now().difference(oldestDate).inDays;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error,
                    radius: 18,
                    child: Text(
                      '${clientPayments.length}',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    '$clientName (${clientPayments.length} cuotas vencidas)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Monto total vencido: \$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Más antigua',
                        style: TextStyle(fontSize: 10, color: AppColors.error.withOpacity(0.7)),
                      ),
                      Text(
                        '$daysLate d',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (clientNames.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navegar a lista completa de atrasados
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Ver todos los atrasados'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}