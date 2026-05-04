import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CreditSummaryCards extends StatelessWidget {
  // Métricas operativas existentes
  final int totalCredits;
  final double totalPaid;
  final int pendingWeeklyQuotas;
  final double pendingBalance;
  final double totalCapital;

  // Nuevas métricas de ganancias
  final double gananciaCobrada;
  final double gananciaMensual;
  final double gananciaTotal;
  final double capitalRecogido;

  final VoidCallback? onTapActiveCredits;
  final VoidCallback? onTapPendingBalance;

  const CreditSummaryCards({
    super.key,
    required this.totalCredits,
    required this.totalPaid,
    required this.pendingWeeklyQuotas,
    required this.pendingBalance,
    required this.totalCapital,
    required this.gananciaCobrada,
    required this.gananciaMensual,
    required this.gananciaTotal,
    required this.capitalRecogido,
    this.onTapActiveCredits,
    this.onTapPendingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── GRID OPERATIVO (4 tarjetas) ───
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildMiniCard(
              title: 'Registros Activos',
              value: totalCredits.toString(),
              icon: Icons.credit_card,
              color: AppColors.primaryGreen,
              onTap: onTapActiveCredits,
            ),
            _buildMiniCard(
              title: 'Total Abonado',
              value: '\$${totalPaid.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: AppColors.info,
            ),
            _buildMiniCard(
              title: 'Cuotas x Semana',
              value: pendingWeeklyQuotas.toString(),
              icon: Icons.calendar_today,
              color: AppColors.warning,
            ),
            _buildMiniCard(
              title: 'Saldo Pendiente',
              value: '\$${pendingBalance.toStringAsFixed(2)}',
              icon: Icons.pending_actions,
              color: AppColors.error,
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ─── ESTADO DE GANANCIAS ───
        _buildSectionHeader('Estado de Ganancias', Icons.trending_up, const Color(0xFF2E7D32)),
        const SizedBox(height: 14),
        _buildGananciasSection(),

        const SizedBox(height: 28),

        // ─── ESTADO DEL CAPITAL ───
        _buildSectionHeader('Estado del Capital', Icons.account_balance, const Color(0xFF1565C0)),
        const SizedBox(height: 14),
        _buildCapitalSection(),
      ],
    );
  }

  // ─── SECCIÓN DE GANANCIAS ───
  Widget _buildGananciasSection() {
    final double progreso = gananciaTotal > 0
        ? (gananciaCobrada / gananciaTotal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFE8F5E9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ganancia Cobrada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.monetization_on, color: Color(0xFF2E7D32), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ganancia Cobrada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${gananciaCobrada.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Ganancia Mensual con barra de progreso
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: Color(0xFF43A047), size: 16),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ganancia Mensual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${gananciaMensual.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF43A047),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progreso * 100).toStringAsFixed(1)}% cobrado',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Meta: \$${gananciaTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            const Divider(height: 28),

            // Ganancia Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events, color: Color(0xFF66BB6A), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ganancia Total Esperada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${gananciaTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECCIÓN DE CAPITAL ───
  Widget _buildCapitalSection() {
    return Row(
      children: [
        Expanded(
          child: _buildCapitalCard(
            title: 'Capital Invertido',
            value: '\$${totalCapital.toStringAsFixed(2)}',
            icon: Icons.account_balance,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCapitalCard(
            title: 'Capital Recogido',
            value: '\$${capitalRecogido.toStringAsFixed(2)}',
            icon: Icons.savings,
            color: const Color(0xFF0277BD),
          ),
        ),
      ],
    );
  }

  // ─── HEADER DE SECCIÓN ───
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── TARJETA MINI (grid operativo) ───
  Widget _buildMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TARJETA DE CAPITAL ───
  Widget _buildCapitalCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
