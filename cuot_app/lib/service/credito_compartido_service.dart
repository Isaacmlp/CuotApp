import 'package:cuot_app/Model/credito_compartido_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class CreditoCompartidoService {
  final SupabaseService _supabase = SupabaseService();

  // 🚀 CACHE: Evita parpadeos en el drawer redireccionando consultas pesadas
  static bool? _cacheTieneCreditosAsignados;
  static bool? _cacheTieneEmpleados;
  static String? _cachedUser;

  static void clearCache() {
    _cacheTieneCreditosAsignados = null;
    _cacheTieneEmpleados = null;
    _cachedUser = null;
  }

  /// Verificar si un propietario tiene empleados asignados (con caché)
  Future<bool> tieneEmpleados(String propietarioNombre) async {
    if (_cachedUser == propietarioNombre.trim() && _cacheTieneEmpleados != null) {
      return _cacheTieneEmpleados!;
    }
    
    // Si no hay caché, lo forzamos cargando la lista (esto actualizará el caché)
    await obtenerCreditosCompartidosPorPropietario(propietarioNombre);
    return _cacheTieneEmpleados ?? false;
  }

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
          .eq('trabajador_nombre', trabajadorNombre.trim())
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
            'propietario_nombre': propietarioNombre.trim(),
            'trabajador_nombre': trabajadorNombre.trim(),
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
          .eq('trabajador_nombre', trabajadorNombre.trim())
          .eq('activo', true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => CreditoCompartido.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerCreditosAsignados: $e');
      return [];
    }
  }

  /// Verificar si un usuario tiene créditos asignados (con caché)
  Future<bool> tieneCreditosAsignados(String nombreUsuario) async {
    // Retornar caché si es del mismo usuario
    if (_cachedUser == nombreUsuario.trim() && _cacheTieneCreditosAsignados != null) {
      return _cacheTieneCreditosAsignados!;
    }

    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select('id')
          .eq('trabajador_nombre', nombreUsuario.trim())
          .eq('activo', true)
          .limit(1);

      final result = List.from(response).isNotEmpty;
      
      // Actualizar caché
      _cachedUser = nombreUsuario.trim();
      _cacheTieneCreditosAsignados = result;

      return result;
    } catch (e) {
      print('❌ Error en tieneCreditosAsignados: $e');
      return false;
    }
  }

  /// Pre-cargar datos para evitar parpadeos en el drawer
  Future<void> preCargarDatosIniciales(String usuario, String rol) async {
    try {
      // 1. Cargar si tiene créditos asignados (Trabajo)
      await tieneCreditosAsignados(usuario);
      
      // 2. Cargar si tiene empleados (solo para admin)
      if (rol == 'admin') {
        await obtenerCreditosCompartidosPorPropietario(usuario);
      }
      
      print('✅ Caché de CreditoCompartidoService inicializado para $usuario');
    } catch (e) {
      print('❌ Error al pre-cargar caché: $e');
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

  /// Obtener créditos que un propietario ha compartido (con caché para el flag de tieneEmpleados)
  Future<List<CreditoCompartido>> obtenerCreditosCompartidosPorPropietario(String propietarioNombre) async {
    // Si solo queremos el flag de si tiene empleados, podríamos usar el caché si existe
    // Pero como esta función devuelve la lista completa, la ejecutamos siempre, pero actualizamos el caché
    
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select()
          .eq('propietario_nombre', propietarioNombre.trim())
          .eq('activo', true);

      final result = List<Map<String, dynamic>>.from(response)
          .map((json) => CreditoCompartido.fromJson(json))
          .toList();

      // Actualizar caché del flag
      if (_cachedUser == propietarioNombre.trim()) {
        _cacheTieneEmpleados = result.isNotEmpty;
      } else {
        _cachedUser = propietarioNombre.trim();
        _cacheTieneEmpleados = result.isNotEmpty;
        _cacheTieneCreditosAsignados = null; // Resetear el otro flag si cambia el usuario
      }

      return result;
    } catch (e) {
      print('❌ Error en obtenerCreditosCompartidosPorPropietario: $e');
      return [];
    }
  }

  /// Obtener TODOS los créditos compartidos activos (para filtrado global)
  Future<List<CreditoCompartido>> obtenerTodosLosCreditosCompartidos() async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Creditos_Compartidos')
          .select()
          .eq('activo', true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => CreditoCompartido.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerTodosLosCreditosCompartidos: $e');
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
