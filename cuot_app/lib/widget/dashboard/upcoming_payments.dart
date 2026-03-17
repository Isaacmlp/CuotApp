import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingPayments extends StatelessWidget {
  final List<PaymentModel> payments;  // 5. Próximos Vencimientos

  const UpcomingPayments({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Próximos Vencimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${payments.length} pendientes',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length > 5 ? 5 : payments.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final daysLeft = payment.date.difference(DateTime.now()).inDays;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${payment.installmentNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    '${payment.clientName ?? 'Cliente'} - Cuota ${payment.installmentNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${payment.concept ?? 'Financiamiento'} - Vence: ${DateFormat('dd/MM/yyyy').format(payment.date)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        daysLeft == 0 
                            ? 'Hoy' 
                            : '$daysLeft días',
                        style: TextStyle(
                          fontSize: 11,
                          color: daysLeft <= 2 
                              ? AppColors.error 
                              : AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (payments.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navegar a lista completa de vencimientos
                    },
                    child: const Text('Ver todos'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}