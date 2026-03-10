import 'package:cuot_app/Model/credit_model.dart';
import 'package:cuot_app/Model/payment_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class CreditService {
  final SupabaseService _supabase = SupabaseService();

  // 🔴 AQUÍ IMPLEMENTARÁS LA LÓGICA DE NEGOCIO PARA OBTENER DATOS DE SUPABASE
  
  // 1. Obtener cantidad total de créditos activos
  Future<int> getTotalCredits() async {
    try {
      // TODO: Implementar consulta a Supabase
      // final response = await _supabase.client
      //     .from('creditos')
      //     .select('count')
      //     .eq('status', 'active')
      //     .single();
      // return response['count'] ?? 0;
      
      // Datos de ejemplo mientras desarrollas
      return 15;
    } catch (e) {
      print('Error obteniendo total de créditos: $e');
      return 0;
    }
  }

  // 2. Obtener dinero total abonado
  Future<double> getTotalPaidAmount() async {
    try {
      // TODO: Implementar consulta a Supabase - suma de todos los pagos
      // final response = await _supabase.client
      //     .from('pagos')
      //     .select('sum(amount)')
      //     .single();
      // return response['sum'] ?? 0.0;
      
      return 12500.50; // Dato de ejemplo
    } catch (e) {
      print('Error obteniendo total abonado: $e');
      return 0.0;
    }
  }

  // 3. Obtener cuotas pendientes por semana
  Future<Map<String, int>> getPendingInstallmentsByWeek() async {
    try {
      // TODO: Calcular cuotas pendientes agrupadas por semana
      // Esto requeriría una consulta más compleja con fechas
      
      return {
        'semana_1': 5,
        'semana_2': 8,
        'semana_3': 4,
        'semana_4': 6,
      };
    } catch (e) {
      print('Error obteniendo cuotas por semana: $e');
      return {};
    }
  }

  // 4. Obtener saldo total pendiente de cuotas
  Future<double> getTotalPendingAmount() async {
    try {
      // TODO: Suma de todos los montos pendientes
      // final response = await _supabase.client
      //     .from('creditos')
      //     .select('sum(pending_amount)')
      //     .eq('status', 'active')
      //     .single();
      // return response['sum'] ?? 0.0;
      
      return 8500.75; // Dato de ejemplo
    } catch (e) {
      print('Error obteniendo saldo pendiente: $e');
      return 0.0;
    }
  }

  // 5. Obtener próximos vencimientos (próximos 7 días)
  Future<List<PaymentModel>> getUpcomingPayments() async {
    try {
      // TODO: Consultar pagos con fecha en los próximos 7 días
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      
      // final response = await _supabase.client
      //     .from('pagos')
      //     .select('*, creditos(*)')
      //     .gte('date', now.toIso8601String())
      //     .lte('date', sevenDaysLater.toIso8601String())
      //     .eq('status', 'pending')
      //     .order('date');
      
      // Datos de ejemplo
      return [
        PaymentModel(
          id: '1',
          creditId: '1',
          amount: 500.0,
          date: DateTime.now().add(const Duration(days: 2)),
          installmentNumber: 3,
          status: 'pending',
        ),
        PaymentModel(
          id: '2',
          creditId: '1',
          amount: 500.0,
          date: DateTime.now().add(const Duration(days: 5)),
          installmentNumber: 4,
          status: 'pending',
        ),
      ];
    } catch (e) {
      print('Error obteniendo próximos vencimientos: $e');
      return [];
    }
  }

  // 6. Obtener cuotas atrasadas
  Future<List<PaymentModel>> getLatePayments() async {
    try {
      // TODO: Consultar pagos con fecha pasada y no pagados
      final now = DateTime.now();
      
      // final response = await _supabase.client
      //     .from('pagos')
      //     .select('*, creditos(*)')
      //     .lt('date', now.toIso8601String())
      //     .eq('status', 'pending')
      //     .order('date');
      
      // Datos de ejemplo
      return [
        PaymentModel(
          id: '3',
          creditId: '2',
          amount: 350.0,
          date: DateTime.now().subtract(const Duration(days: 5)),
          installmentNumber: 2,
          status: 'pending',
        ),
      ];
    } catch (e) {
      print('Error obteniendo cuotas atrasadas: $e');
      return [];
    }
  }

  // Obtener todos los créditos activos (para listados)
  Future<List<CreditModel>> getActiveCredits() async {
    try {
      // TODO: Implementar consulta a Supabase
      // final response = await _supabase.client
      //     .from('creditos')
      //     .select('*')
      //     .eq('status', 'active');
      
      // return (response as List)
      //     .map((json) => CreditModel.fromJson(json))
      //     .toList();
      
      return []; // Datos de ejemplo vacíos
    } catch (e) {
      print('Error obteniendo créditos activos: $e');
      return [];
    }
  }
}