import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CreditSummaryCards extends StatelessWidget {
  final int totalCredits; // 1. Cantidad de Créditos
  final double totalPaid; // 2. Dinero abonado
  final int pendingWeeklyQuotas; // 3. Cuotas pendientes por semana
  final double pendingBalance; // 4. Saldo de Cuotas Pendiente
  final double totalCapital; // 5. Capital total
  final double capitalRecuperado; // 6. Capital recuperado
  final double gananciaPorCobrarMensual; // 7. Ganancia por cobrar (mes actual)
  final double gananciaPorCobrarTotal; // 8. Ganancia por cobrar (total)
  final double gananciaMensual; // 9. Ganancia del mes actual

  final VoidCallback? onTapActiveCredits; // 👈 NUEVO: Callback para navegación
  final VoidCallback? onTapPendingBalance; // 👈 NUEVO: Opcional para el futuro

  const CreditSummaryCards({
    super.key,
    required this.totalCredits,
    required this.totalPaid,
    required this.pendingWeeklyQuotas,
    required this.pendingBalance,
    this.onTapActiveCredits,
    this.onTapPendingBalance,
    required this.totalCapital,
    required this.capitalRecuperado,
    required this.gananciaPorCobrarMensual,
    required this.gananciaPorCobrarTotal,
    required this.gananciaMensual,
  });

  @override
  Widget build(BuildContext context) {
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    final mesActual = meses[DateTime.now().month - 1];

    Widget smallCard(String title, String value, IconData icon, Color color, {String? extraInfo, VoidCallback? onTap}) {
       return AspectRatio(
         aspectRatio: 1.25,
         child: _buildSummaryCard(title: title, value: value, icon: icon, color: color, extraInfo: extraInfo, onTap: onTap),
       );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Resumen General', Icons.dashboard_customize),
        AspectRatio(
          aspectRatio: 2.8,
          child: _buildSummaryCard(
            title: 'Ganancia por Cobrar ($mesActual)',
            value: '\$${gananciaPorCobrarMensual.toStringAsFixed(2)}',
            icon: Icons.savings,
            color: const Color(0xFF00897B),
            extraInfo: 'Falta por cobrar este mes'
          ),
        ),
        const SizedBox(height: 12),
        _buildUnifiedActivityCard(onTapActiveCredits),
        const SizedBox(height: 20),
        
        _buildSectionTitle('Estado del Capital', Icons.account_balance),
        _buildCapitalProgressCard(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: smallCard('Total Abonado', '\$${totalPaid.toStringAsFixed(2)}', Icons.account_balance_wallet, AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: smallCard('Saldo Pendiente', '\$${pendingBalance.toStringAsFixed(2)}', Icons.pending_actions, AppColors.error)),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Estado de Ganancias', Icons.trending_up),
        Row(
          children: [
            Expanded(child: smallCard('Ganancia Mensual', '\$${gananciaMensual.toStringAsFixed(2)}', Icons.calendar_month, const Color(0xFF7B1FA2), extraInfo: mesActual)),
            const SizedBox(width: 12),
            Expanded(child: smallCard('Pendiente Total', '\$${gananciaPorCobrarTotal.toStringAsFixed(2)}', Icons.auto_graph, const Color(0xFF1565C0))),
          ],
        ),
      ],
    );
  }

  Widget _buildUnifiedActivityCard(VoidCallback? onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat(Icons.credit_card, AppColors.primaryGreen, totalCredits.toString(), 'Registros Activos'),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              _buildMiniStat(Icons.calendar_today, AppColors.warning, pendingWeeklyQuotas.toString(), 'Cuotas x Semana'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, String value, String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalProgressCard() {
    final double progress = totalCapital > 0 ? capitalRecuperado / totalCapital : 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primaryGreen.withOpacity(0.05)],
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pie_chart, color: AppColors.primaryGreen, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Recuperación de Capital', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recuperado', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('\$${capitalRecuperado.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Prestado Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('\$${totalCapital.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    String? extraInfo,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.08),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (extraInfo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        extraInfo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color.withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
