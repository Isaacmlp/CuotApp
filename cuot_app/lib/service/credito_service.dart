import 'package:supabase_flutter/supabase_flutter.dart';

class CreditoService {
  final SupabaseClient _supabase = Supabase.instance.client;
/*
  // 🔧 LÓGICA: Crear un nuevo crédito
  Future<CreditoModel?> crearCredito(CreditoModel credito) async {
    try {
      // Primero, crear el crédito en la BD
      final response = await _supabase
          .schema("Financiamiento")
          .from('Productos_Financiados')
          .insert(credito.toJson())
          .select()
          .single();

      return CreditoModel.fromJson(response);
    } catch (e) {
      print('Error creando crédito: $e');
      return null;
    }
  }

  // 🔧 LÓGICA: Obtener todos los créditos
  Future<List<CreditoModel>> obtenerCreditos() async {
    try {
      final response = await _supabase
          .from('creditos')
          .select('*, clientes(*)')
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => CreditoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo créditos: $e');
      return [];
    }
  }

  // 🔧 LÓGICA: Obtener créditos por cliente
  Future<List<CreditoModel>> obtenerCreditosPorCliente(int clienteId) async {
    try {
      final response = await _supabase
          .from('creditos')
          .select()
          .eq('cliente_id', clienteId)
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => CreditoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo créditos del cliente: $e');
      return [];
    }
  }

  // 🔧 LÓGICA: Actualizar estado de crédito
  Future<bool> actualizarEstadoCredito(int creditoId, String nuevoEstado) async {
    try {
      await _supabase
          .from('creditos')
          .update({'estado': nuevoEstado})
          .eq('id', creditoId);
      return true;
    } catch (e) {
      print('Error actualizando estado: $e');
      return false;
    }
  }

  // 🔧 LÓGICA: Registrar pago de cuota
  Future<bool> registrarPago(int creditoId, double monto) async {
    try {
      // Obtener crédito actual
      final credito = await obtenerCreditoPorId(creditoId);
      if (credito == null) return false;

      // Calcular nuevo saldo pendiente
      final nuevoSaldo = credito.saldoPendiente - monto;
      
      // Actualizar saldo pendiente
      await _supabase
          .from('creditos')
          .update({
            'saldo_pendiente': nuevoSaldo,
            'estado': nuevoSaldo <= 0 ? 'pagado' : 'activo',
          })
          .eq('id', creditoId);

      // Registrar el pago en tabla de pagos (opcional)
      await _supabase.from('pagos').insert({
        'credito_id': creditoId,
        'monto': monto,
        'fecha_pago': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error registrando pago: $e');
      return false;
    }
  }

  // 🔧 LÓGICA: Obtener crédito por ID
  Future<CreditoModel?> obtenerCreditoPorId(int id) async {
    try {
      final response = await _supabase
          .from('creditos')
          .select()
          .eq('id', id)
          .single();

      return CreditoModel.fromJson(response);
    } catch (e) {
      print('Error obteniendo crédito: $e');
      return null;
    }
  }
  */
}