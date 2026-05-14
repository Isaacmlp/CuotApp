import 'package:cuot_app/Model/renovacion_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class RenovacionService {
  final SupabaseService _supabase = SupabaseService();

  /// Crear una nueva renovación + primer registro de historial
  Future<Renovacion> crearRenovacion(Renovacion renovacion) async {
    try {
      // 1. Insertar la renovación
      final data = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .insert(renovacion.toJson())
          .select()
          .single();

      final nuevaRenovacion = Renovacion.fromJson(data);

      // NOTA: El abono ya está incorporado en el cálculo de verdaderoGrossTotal
      // dentro de _aplicarRenovacionAlCredito, por lo que NO se inserta en Pagos
      // para evitar doble descuento del abono al calcular el saldo pendiente.

      // 3. Si está aprobada, actualizar el crédito original
      if (renovacion.estado == 'aprobada') {
        print('✅ Aplicando renovación aprobada al crédito: ${renovacion.creditoOriginalId}');
        await _aplicarRenovacionAlCredito(renovacion);
      } else {
        // Si está pendiente o solicitada, no aplicamos nada al crédito todavía
        print('🕒 Renovación estado: ${renovacion.estado}. No se aplica al crédito todavía.');
      }

      // 4. Registrar en historial
      await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .insert(HistorialRenovacion(
            renovacionId: nuevaRenovacion.id!,
            estadoAnterior: null,
            usuarioId: renovacion.usuarioAutoriza,
            observaciones: nuevaRenovacion.estado == 'aprobada' 
                ? 'Renovación creada y aplicada' 
                : 'Renovación solicitada (en espera)',
          ).toJson());

      // Determinar si debemos aplicar el efecto financiero de inmediato
      // IMPORTANTE: Solo se aplica si el estado es 'aprobada' (por ejemplo, si lo creó un Admin)
      final String estadoFinal = nuevaRenovacion.estado;
      debugPrint('🕒 Renovación ID: ${nuevaRenovacion.id} - Estado: $estadoFinal');

      if (estadoFinal == 'aprobada') {
        debugPrint('🚀 Aplicando efecto financiero de renovación inmediata...');
        await _aplicarRenovacionAlCredito(nuevaRenovacion);
      } else {
        debugPrint('🕒 Renovación estado: $estadoFinal. No se aplica al crédito todavía (esperando aprobación).');
      }

      return nuevaRenovacion;
    } catch (e) {
      debugPrint('❌ Error en crearRenovacion: $e');
      rethrow;
    }
  }

  Future<void> _aplicarRenovacionAlCredito(Renovacion renovacion) async {
    final condicionesNuevas = renovacion.condicionesNuevas;
    final tipoCredito = condicionesNuevas['tipo_credito'] ?? 'cuotas';

    // El formulario envía en 'monto_total' el nuevo saldo pendiente DESEADO
    // (ya con el abono descontado: saldoPendiente + mora - abono).
    final double nuevoSaldoPendienteDeseado =
        (condicionesNuevas['monto_total'] as num).toDouble();

    // PIZARRA LIMPIA: El gross en DB es exactamente el nuevo saldo deseado.
    final double verdaderoGrossTotal = nuevoSaldoPendienteDeseado;

    // La nueva ganancia pactada es el monto_mora extra de esta renovación
    final double nuevaMora = (condicionesNuevas['monto_mora'] ?? 0).toDouble();
    
    // El nuevo costo de inversión es el total menos la ganancia pactada
    final double nuevoCostoInversion = verdaderoGrossTotal - nuevaMora;

    Map<String, dynamic> updateData = {
      'costo_inversion': nuevoCostoInversion,
      'margen_ganancia': nuevaMora,
      'numero_cuotas': renovacion.nuevoPlazo,
      'fecha_inicio': condicionesNuevas['fecha_inicio_nueva'],
    };

    if (tipoCredito == 'unico' && condicionesNuevas['fecha_pago_nueva'] != null) {
      updateData['fecha_vencimiento'] = condicionesNuevas['fecha_pago_nueva'];
    } else {
      // Para cuotas, el vencimiento es la fecha de la última cuota renovada
      final List<dynamic> cuotasRenovadas = condicionesNuevas['cuotas_renovadas'] ?? [];
      if (cuotasRenovadas.isNotEmpty) {
        updateData['fecha_vencimiento'] = cuotasRenovadas.last['fecha'];
      }
    }

    await _supabase.client
        .schema('Financiamientos')
        .from('Creditos')
        .update(updateData)
        .eq('id', renovacion.creditoOriginalId);

    // 2. Gestionar Cuotas
    if (tipoCredito == 'unico') {
      // Actualizar la cuota única existente o crearla si no hay
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .update({
            'monto': nuevoSaldoPendienteDeseado,
            'pagada': false,
            if (condicionesNuevas['fecha_pago_nueva'] != null) 
              'fecha_pago': condicionesNuevas['fecha_pago_nueva'],
          })
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('numero_cuota', 1);
    } else {
      // Eliminar cuotas NO PAGADAS
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .delete()
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('pagada', false);

      // Insertar las nuevas cuotas editadas
      final List<dynamic> cuotasRenovadas = condicionesNuevas['cuotas_renovadas'] ?? [];
      // Obtener el número de la última cuota pagada para no duplicar índices
      final List<dynamic> pagadas = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas')
          .select('numero_cuota')
          .eq('credito_id', renovacion.creditoOriginalId)
          .eq('pagada', true)
          .order('numero_cuota', ascending: false)
          .limit(1);

      int contador = 1;
      if (pagadas.isNotEmpty) {
        contador = (pagadas[0]['numero_cuota'] as int) + 1;
      }
      
      final List<Map<String, dynamic>> cuotasParaInsertar = [];
      for (var c in cuotasRenovadas) {
        cuotasParaInsertar.add({
          'credito_id': renovacion.creditoOriginalId,
          'numero_cuota': contador++, // Re-numeramos para mantener orden
          'monto': c['monto'],
          'fecha_pago': c['fecha'],
          'pagada': false,
        });
      }

      if (cuotasParaInsertar.isNotEmpty) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas')
            .insert(cuotasParaInsertar);
      }
    }
  }

  /// Obtener todas las renovaciones (con datos de cliente y crédito)
  Future<List<Renovacion>> getRenovaciones(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('''
            *,
            Creditos!credito_original_id(concepto, Clientes(nombre))
          ''')
          .eq('usuario_autoriza', usuarioNombre)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((json) {
        return Renovacion.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error al obtener renovaciones: $e');
      return [];
    }
  }

  /// Obtener renovaciones con datos raw para la UI
  Future<List<Map<String, dynamic>>> getRenovacionesRaw(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('''
            *,
            Creditos!credito_original_id(concepto, costo_inversion, margen_ganancia, numero_cuotas, modalidad_pago, Clientes(nombre, telefono))
          ''')
          .eq('usuario_autoriza', usuarioNombre)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener renovaciones raw: $e');
      return [];
    }
  }

  /// Obtener renovaciones de un crédito específico
  Future<List<Renovacion>> getRenovacionesPorCredito(String creditoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select()
          .eq('credito_original_id', creditoId)
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => Renovacion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener renovaciones del crédito: $e');
      return [];
    }
  }

  /// Contar renovaciones de un crédito
  Future<int> contarRenovaciones(String creditoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('id')
          .eq('credito_original_id', creditoId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Actualizar estado de una renovación + registrar historial
  Future<void> actualizarEstado({
    required String renovacionId,
    required String estadoAnterior,
    required String estadoNuevo,
    String? usuarioId,
    String? observaciones,
  }) async {
    try {
      // 1. Actualizar estado
      await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .update({'estado': estadoNuevo})
          .eq('id', renovacionId);

      // 2. Registrar en historial
      await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .insert(HistorialRenovacion(
            renovacionId: renovacionId,
            estadoAnterior: estadoAnterior,
            estadoNuevo: estadoNuevo,
            usuarioId: usuarioId,
            observaciones: observaciones,
          ).toJson());
    } catch (e) {
      print('Error al actualizar estado de renovación: $e');
      rethrow;
    }
  }

  /// Obtener historial de cambios de una renovación
  Future<List<HistorialRenovacion>> getHistorialRenovacion(String renovacionId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .select()
          .eq('renovacion_id', renovacionId)
          .order('fecha_cambio', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => HistorialRenovacion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error al obtener historial: $e');
      return [];
    }
  }

  /// Obtener renovaciones pendientes para un administrador
  Future<List<Map<String, dynamic>>> getRenovacionesPendientes(String adminNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select('''
            *,
            Creditos!credito_original_id(concepto, Clientes(nombre))
          ''')
          .eq('estado', 'solicitada')
          .eq('usuario_autoriza', adminNombre) // El usuario autoriza final es el admin que lo debe ver
          .order('fecha_renovacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error en getRenovacionesPendientes: $e');
      return [];
    }
  }

  /// Aprobar una renovación pendiente
  Future<void> aprobarRenovacion(String id) async {
    try {
      // 1. Obtener la renovación completa
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .select()
          .eq('id', id)
          .single();
      
      final renovacion = Renovacion.fromJson(response);

      // 2. Aplicar al crédito
      await _aplicarRenovacionAlCredito(renovacion);

      // 3. Actualizar estado
      await _supabase.client
          .schema('Financiamientos')
          .from('Renovaciones')
          .update({'estado': 'aprobada'})
          .eq('id', id);
          
      // 4. Registrar en historial
      await _supabase.client
          .schema('Financiamientos')
          .from('Historial_Renovaciones')
          .insert(HistorialRenovacion(
            renovacionId: id,
            estadoAnterior: 'solicitada',
            estadoNuevo: 'aprobada',
            usuarioId: renovacion.usuarioAutoriza,
            observaciones: 'Renovación aprobada por administrador',
          ).toJson());

    } catch (e) {
      print('❌ Error en aprobarRenovacion: $e');
      rethrow;
    }
  }
}
