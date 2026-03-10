import 'package:cuot_app/Controller/dashboard_controller.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/ui/credito_page.dart';
import 'package:cuot_app/widget/dashboard/credit_summary_cards.dart';
import 'package:cuot_app/widget/dashboard/custom_drawer.dart';
import 'package:cuot_app/widget/dashboard/overdue_payments.dart';
import 'package:cuot_app/widget/dashboard/upcoming_payments.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  final String? userName;
  final String? correo;

  // Llave global del Scaffold para controlar el Drawer manualmente
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DashboardScreen({super.key, required this.correo, required this.userName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardController(correo: correo, userName: userName),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          // Si el Drawer está abierto, ciérralo manualmente
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
          } else {
            // Si no hay Drawer abierto, maneja retroceso normal saliendo de la app o pantalla
            Navigator.of(context).pop();
          }
        },
        child: Consumer<DashboardController>(
            builder: (context, controller, child) {
              return Scaffold(
                drawer: CustomDrawer(nombre_usuario: userName ?? "Usuario no encontrado"),
                //Drawer(child: Center(child: Text(userName ?? "prueba")),),
                body: RefreshIndicator(
                  onRefresh: () => controller.refreshData(),
                  color: AppColors.primaryGreen,
                  child: CustomScrollView(
                    slivers: [
                      // App Bar personalizada
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: true,
                        pinned: true,
                        backgroundColor: AppColors.pureWhite,
                        elevation: 0,
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            color: AppColors.primaryGreen,
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            'Bienvenido ${controller.getName()}',
                            style: TextStyle(
                              color: AppColors.darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.pureWhite, AppColors.offWhite],
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            color: AppColors.primaryGreen,
                            onPressed: () {
                              // TODO: Navegar a notificaciones
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            color: AppColors.primaryGreen,
                            onPressed: () {
                              // TODO: Abrir búsqueda
                            },
                          ),
                        ],
                      ),
                
                      // Contenido principal
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (controller.isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (controller.errorMessage != null)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        controller.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => controller.refreshData(),
                                        child: const Text('Reintentar'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              // 1-4. Tarjetas de resumen
                              CreditSummaryCards(
                                totalCredits: controller.totalCredits,
                                totalPaid: controller.totalPaid,
                                pendingWeeklyQuotas:
                                    controller.pendingWeeklyQuotas,
                                pendingBalance: controller.pendingBalance,
                              ),
                
                              const SizedBox(height: 20),
                
                              // 5. Próximos vencimientos
                              UpcomingPayments(
                                payments: controller.upcomingPayments,
                              ),
                
                              const SizedBox(height: 20),
                
                              // 6. Cuotas atrasadas
                              OverduePayments(payments: controller.latePayments),
                
                              const SizedBox(height: 20),
                
                              // Botón para nuevo crédito
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => CreditoPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nuevo Crédito'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 45),
                                    backgroundColor: AppColors.primaryGreen,
                                    foregroundColor: AppColors.pureWhite,
                                  ),
                                ),
                              ),
                
                              const SizedBox(height: 20),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
}
