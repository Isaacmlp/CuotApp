import 'package:cuot_app/Model/bitacora_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class BitacoraService {
  final SupabaseService _supabase = SupabaseService();

  /// Registrar una actividad en la bitácora
  Future<void> registrarActividad({
    required String usuarioNombre,
    required String accion,
    String? descripcion,
    String? entidadTipo,
    String? entidadId,
  }) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Bitacora_Actividad')
          .insert({
            'usuario_nombre': usuarioNombre,
            'accion': accion,
            'descripcion': descripcion,
            'entidad_tipo': entidadTipo,
            'entidad_id': entidadId,
          });
    } catch (e) {
      // Registrar log local pero lanzar para que la app se entere en dev
      print('⚠️ Error registrando actividad en bitácora: $e');
      // No rethrow para no romper pagos o crear créditos, pero lo imprimirá
    }
  }

  /// Obtener actividades de la bitácora (para panel admin)
  Future<List<BitacoraActividad>> obtenerActividades({
    int limit = 50,
    List<String>? usuariosFilter,
  }) async {
    try {
      var query = _supabase.client
          .schema('Usuarios')
          .from('Bitacora_Actividad')
          .select();

      if (usuariosFilter != null && usuariosFilter.isNotEmpty) {
        query = query.inFilter('usuario_nombre', usuariosFilter.map((u) => u.trim()).toList());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => BitacoraActividad.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerActividades: $e');
      rethrow;
    }
  }
}
