import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class UserAdminService {
  final SupabaseService _supabase = SupabaseService();

  /// Obtener todos los usuarios con filtros opcionales
  Future<List<Usuario>> getUsuarios({
    String? searchQuery,
    String? rolFilter,
    bool? activoFilter,
  }) async {
    try {
      var query = _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select();

      final List<Map<String, dynamic>> response = await query;

      List<Usuario> usuarios = response.map((json) => Usuario.fromJson(json)).toList();

      // Filtrar por búsqueda
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        usuarios = usuarios.where((u) =>
            u.nombreCompleto.toLowerCase().contains(q) ||
            u.correoElectronico.toLowerCase().contains(q)).toList();
      }

      // Filtrar por rol
      if (rolFilter != null && rolFilter.isNotEmpty) {
        usuarios = usuarios.where((u) => u.rol == rolFilter).toList();
      }

      // Filtrar por estado activo
      if (activoFilter != null) {
        usuarios = usuarios.where((u) => u.activo == activoFilter).toList();
      }

      return usuarios;
    } catch (e) {
      print('❌ Error en getUsuarios: $e');
      rethrow;
    }
  }

  /// Crear un nuevo usuario (desde panel admin)
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String telefono,
    required String contrasena,
    required String rol,
    required String creadoPor,
  }) async {
    try {
      // 1. Verificar que el correo no exista
      final existente = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select('id')
          .eq('Correo_Electronico', correo)
          .maybeSingle();

      if (existente != null) {
        throw Exception('Ya existe un usuario con ese correo electrónico');
      }

      // 2. Insertar en tabla Usuarios
      final usuarioResponse = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .insert({
            'Nombre_Completo': nombre,
            'Correo_Electronico': correo,
            'Telefono': telefono,
            'rol': rol,
            'creado_por': creadoPor,
            'activo': true,
          })
          .select()
          .single();

      // 3. Insertar en tabla Credenciales
      await _supabase.client
          .schema('Usuarios')
          .from('Credenciales')
          .insert({
            'Correo_Electronico': correo,
            'Contrasena': contrasena,
          });

      return Usuario.fromJson(usuarioResponse);
    } catch (e) {
      print('❌ Error en crearUsuario: $e');
      rethrow;
    }
  }

  /// Editar rol de un usuario
  Future<void> editarRol(String usuarioId, String nuevoRol) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .update({'rol': nuevoRol})
          .eq('id', usuarioId);
    } catch (e) {
      print('❌ Error en editarRol: $e');
      rethrow;
    }
  }

  /// Activar o desactivar un usuario
  Future<void> toggleActivo(String usuarioId, bool activo) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .update({'activo': activo})
          .eq('id', usuarioId);
    } catch (e) {
      print('❌ Error en toggleActivo: $e');
      rethrow;
    }
  }

  /// Resetear contraseña de un usuario
  Future<void> resetearContrasena(String correo, String nuevaContrasena) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Credenciales')
          .update({'Contrasena': nuevaContrasena})
          .eq('Correo_Electronico', correo);
    } catch (e) {
      print('❌ Error en resetearContrasena: $e');
      rethrow;
    }
  }

  /// Obtener rol y estado de un usuario por correo (para login inteligente)
  Future<Map<String, dynamic>?> obtenerDatosRolPorCorreo(String correo) async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select('rol, activo, creado_por, Nombre_Completo')
          .eq('Correo_Electronico', correo)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Error en obtenerDatosRolPorCorreo: $e');
      return null;
    }
  }

  /// Buscar usuarios para selector (al compartir créditos)
  Future<List<Usuario>> buscarUsuarios(String query) async {
    try {
      final response = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select()
          .eq('activo', true);

      List<Usuario> usuarios = List<Map<String, dynamic>>.from(response)
          .map((json) => Usuario.fromJson(json))
          .toList();

      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        usuarios = usuarios.where((u) =>
            u.nombreCompleto.toLowerCase().contains(q) ||
            u.correoElectronico.toLowerCase().contains(q)).toList();
      }

      return usuarios;
    } catch (e) {
      print('❌ Error en buscarUsuarios: $e');
      return [];
    }
  }
}
