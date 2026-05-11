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
      // No lanzar error para no interrumpir la operación principal
      print('⚠️ Error registrando actividad en bitácora: $e');
    }
  }

  /// Obtener actividades de la bitácora (para panel admin)
  Future<List<BitacoraActividad>> obtenerActividades({
    int limit = 50,
    String? usuarioFilter,
  }) async {
    try {
      var query = _supabase.client
          .schema('Usuarios')
          .from('Bitacora_Actividad')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<Map<String, dynamic>> response = await query;

      List<BitacoraActividad> actividades = response
          .map((json) => BitacoraActividad.fromJson(json))
          .toList();

      // Filtrar por usuario si se especifica
      if (usuarioFilter != null && usuarioFilter.isNotEmpty) {
        actividades = actividades
            .where((a) => a.usuarioNombre.toLowerCase()
                .contains(usuarioFilter.toLowerCase()))
            .toList();
      }

      return actividades;
    } catch (e) {
      print('❌ Error en obtenerActividades: $e');
      return [];
    }
  }
}
