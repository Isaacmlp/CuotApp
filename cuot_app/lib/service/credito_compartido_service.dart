import 'package:cuot_app/Model/credito_compartido_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class CreditoCompartidoService {
  final SupabaseService _supabase = SupabaseService();

  /// Compartir un crédito con un trabajador
  Future<CreditoCompartido> compartirCredito({
    required String creditoId,
    String tipoEntidad = 'credito',
    required String propietarioNombre,
    required String trabajadorNombre,
    String permisos = 'lectura',
  }) async {
    try {
      // Verificar que no esté ya compartido con ese trabajador
      final existente = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select('id')
          .eq('credito_id', creditoId)
          .eq('trabajador_nombre', trabajadorNombre)
          .eq('activo', true)
          .maybeSingle();

      if (existente != null) {
        throw Exception('Este crédito ya está compartido con ese usuario');
      }

      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .insert({
            'credito_id': creditoId,
            'tipo_entidad': tipoEntidad,
            'propietario_nombre': propietarioNombre,
            'trabajador_nombre': trabajadorNombre,
            'permisos': permisos,
            'activo': true,
          })
          .select()
          .single();

      return CreditoCompartido.fromJson(response);
    } catch (e) {
      print('❌ Error en compartirCredito: $e');
      rethrow;
    }
  }

  /// Obtener créditos asignados a un trabajador
  Future<List<CreditoCompartido>> obtenerCreditosAsignados(String trabajadorNombre) async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select()
          .eq('trabajador_nombre', trabajadorNombre)
          .eq('activo', true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => CreditoCompartido.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerCreditosAsignados: $e');
      return [];
    }
  }

  /// Verificar si un usuario tiene créditos asignados (para mostrar opción en drawer)
  Future<bool> tieneCreditosAsignados(String nombreUsuario) async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select('id')
          .eq('trabajador_nombre', nombreUsuario)
          .eq('activo', true)
          .limit(1);

      return List.from(response).isNotEmpty;
    } catch (e) {
      print('❌ Error en tieneCreditosAsignados: $e');
      return false;
    }
  }

  /// Revocar acceso a un crédito compartido
  Future<void> revocarAcceso(String compartidoId) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .update({'activo': false})
          .eq('id', compartidoId);
    } catch (e) {
      print('❌ Error en revocarAcceso: $e');
      rethrow;
    }
  }

  /// Obtener créditos que un propietario ha compartido
  Future<List<CreditoCompartido>> obtenerCreditosCompartidosPorPropietario(String propietarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select()
          .eq('propietario_nombre', propietarioNombre)
          .eq('activo', true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => CreditoCompartido.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerCreditosCompartidosPorPropietario: $e');
      return [];
    }
  }

  /// Actualizar permisos de un crédito compartido
  Future<void> actualizarPermisos(String compartidoId, String nuevosPermisos) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .update({'permisos': nuevosPermisos})
          .eq('id', compartidoId);
    } catch (e) {
      print('❌ Error en actualizarPermisos: $e');
      rethrow;
    }
  }
}
