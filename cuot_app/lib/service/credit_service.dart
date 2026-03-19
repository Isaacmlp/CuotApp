import 'package:cuot_app/core/supabase/supabase_service.dart';

class CreditService {
  final SupabaseService _supabase = SupabaseService();

  // 🚀 OPTIMIZADO: Obtener TODO en una sola consulta (Créditos + Clientes + Cuotas + Pagos)
  Future<List<Map<String, dynamic>>> getFullCreditsData(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Creditos')
          .select('''
            *,
            Clientes(*),
            Cuotas(*),
            Pagos(*)
          ''')
          .eq('usuario_nombre', usuarioNombre)
          .order('id', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getFullCreditsData: $e');
      return [];
    }
  }

  // 7. Guardar un pago y actualizar la cuota correspondiente
  Future<void> savePayment({
    required String creditId,
    required int numeroCuota,
    required double montoPagado,
    required DateTime fechaPago,
    required String metodoPago,
    String? referencia,
    String? observaciones,
    bool esPagoParcial = false,
  }) async {
    try {
      // 1. Insertar el registro de pago
      await _supabase.client
          .schema('Financiamientos')
          .from('Pagos')
          .insert({
            'credito_id': creditId,
            'numero_cuota': numeroCuota,
            'monto': montoPagado,
            'fecha_pago_real': fechaPago.toIso8601String(),
            'metodo_pago': metodoPago,
            'referencia': referencia,
            'observaciones': observaciones,
          });

      // 2. Obtener la cuota actual
      final List<dynamic> cuotas = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('monto')
          .eq('credito_id', creditId)
          .eq('numero_cuota', numeroCuota);

      if (cuotas.isNotEmpty) {
        final double montoActual = (cuotas[0]['monto'] as num).toDouble();
        final double nuevoMonto = montoActual - montoPagado;
        final bool pagada = nuevoMonto <= 0.01; // Tolerancia para punto flotante

        // 3. Actualizar la cuota
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .update({
              'monto': nuevoMonto > 0 ? nuevoMonto : 0,
              'pagada': pagada,
            })
            .eq('credito_id', creditId)
            .eq('numero_cuota', numeroCuota);
      }
    } catch (e) {
      print('Error al guardar pago: $e');
      rethrow;
    }
  }
}