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
                  'Cuotas Atrasadas',
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
              itemCount: payments.length > 3 ? 3 : payments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final daysLate = DateTime.now().difference(payment.date).inDays;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error,
                    radius: 18,
                    child: Text(
                      '$daysLate',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    'Crédito #${payment.creditId} - Cuota ${payment.installmentNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Vencía: ${DateFormat('dd/MM/yyyy').format(payment.date)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      Text(
                        '$daysLate días',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (payments.length > 3)
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