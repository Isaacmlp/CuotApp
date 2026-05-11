import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CreditSummaryCards extends StatelessWidget {
  final int totalCredits;
  final double totalPaid;
  final int pendingWeeklyQuotas;
  final double pendingBalance;
  final double totalCapital;
  final double capitalRecuperado;
  final double gananciaPorCobrarMensual;
  final double gananciaPorCobrarTotal;
  final double gananciaMensual;

  final VoidCallback? onTapActiveCredits;
  final VoidCallback? onTapPendingBalance;

  const CreditSummaryCards({
    super.key,
    required this.totalCredits,
    required this.totalPaid,
    required this.pendingWeeklyQuotas,
    required this.pendingBalance,
    required this.totalCapital,
    required this.capitalRecuperado,
    required this.gananciaPorCobrarMensual,
    required this.gananciaPorCobrarTotal,
    required this.gananciaMensual,
    this.onTapActiveCredits,
    this.onTapPendingBalance,
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
            title: 'Capital Total Invertido',
            value: '\$${totalCapital.toStringAsFixed(2)}',
            icon: Icons.account_balance,
            color: AppColors.primaryGreen,
            extraInfo: 'Dinero actual'
          ),
        ),
        const SizedBox(height: 12),
        _buildUnifiedActivityCard(onTapActiveCredits),
        const SizedBox(height: 20),
        
        // ─── ESTADO DE GANANCIAS ───
        _buildSectionTitle('Estado de Ganancias', Icons.trending_up),
        _buildGananciasCard(mesActual),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: smallCard('Ganancia Mensual', '\$${gananciaMensual.toStringAsFixed(2)}', Icons.calendar_month, const Color(0xFF7B1FA2), extraInfo: mesActual)),
            const SizedBox(width: 12),
            Expanded(child: smallCard('Pendiente Total', '\$${gananciaPorCobrarTotal.toStringAsFixed(2)}', Icons.auto_graph, const Color(0xFF1565C0))),
          ],
        ),
        const SizedBox(height: 20),

        // ─── ESTADO DEL CAPITAL ───
        _buildSectionTitle('Estado del Capital', Icons.account_balance),
        Row(
          children: [
            Expanded(child: smallCard('Capital Invertido', '\$${totalCapital.toStringAsFixed(2)}', Icons.account_balance, AppColors.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: smallCard('Capital Recogido', '\$${capitalRecuperado.toStringAsFixed(2)}', Icons.savings, const Color(0xFF0277BD))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: smallCard('Total Abonado', '\$${totalPaid.toStringAsFixed(2)}', Icons.account_balance_wallet, AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: smallCard('Saldo Pendiente', '\$${pendingBalance.toStringAsFixed(2)}', Icons.pending_actions, AppColors.error)),
          ],
        ),
      ],
    );
  }

  // ─── TARJETA DE GANANCIAS CON BARRA DE PROGRESO ───
  Widget _buildGananciasCard(String mesActual) {
    final double gananciaTotal = gananciaMensual + gananciaPorCobrarTotal;
    final double progreso = gananciaTotal > 0
        ? (gananciaMensual / gananciaTotal).clamp(0.0, 1.0)
        : 0.0;

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
            colors: [Colors.white, const Color(0xFFE8F5E9)],
          ),
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
                        color: const Color(0xFF2E7D32).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.monetization_on, color: Color(0xFF2E7D32), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('Ganancia Cobrada ($mesActual)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progreso * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
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
                    Text('Cobrado', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('\$${gananciaMensual.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2E7D32))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Meta Total', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('\$${gananciaTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.all(14),
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
