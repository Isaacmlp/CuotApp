import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/core/supabase/supabase_service.dart';

class UserAdminService {
  final SupabaseService _supabase = SupabaseService();

  /// Obtener todos los usuarios con filtros opcionales
  Future<List<Usuario>> getUsuarios({
    String? searchQuery,
    String? rolFilter,
    bool? activoFilter,
    String? creadoPorFilter,
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

      // Filtrar por creador (aislamiento de empleados por admin)
      if (creadoPorFilter != null && creadoPorFilter.isNotEmpty) {
        usuarios = usuarios.where((u) => u.creadoPor == creadoPorFilter).toList();
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
    String? cedula,
  }) async {
    try {
      // 1. Verificar que el correo no exista en ninguna de las dos tablas
      final existenteUsuarios = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select('Correo_Electronico')
          .eq('Correo_Electronico', correo)
          .maybeSingle();

      final existenteCredenciales = await _supabase.client
          .schema('Usuarios')
          .from('Credenciales')
          .select('Correo_Electronico')
          .eq('Correo_Electronico', correo)
          .maybeSingle();

      if (existenteUsuarios != null || existenteCredenciales != null) {
        throw Exception('Ya existe un usuario con ese correo electrónico');
      }

      // 2. Verificar que el teléfono no exista
      final existenteTelefono = await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .select('Telefono')
          .eq('Telefono', telefono)
          .maybeSingle();

      if (existenteTelefono != null) {
        throw Exception('Ya existe un usuario con ese número de teléfono');
      }

      // 3. Verificar que la cédula no exista
      if (cedula != null && cedula.isNotEmpty) {
        final existenteCedula = await _supabase.client
            .schema('Usuarios')
            .from('Usuarios')
            .select('Cedula')
            .eq('Cedula', cedula)
            .maybeSingle();

        if (existenteCedula != null) {
          throw Exception('Ya existe un usuario con esa cédula / ID');
        }
      }

      try {
        // 4. Insertar en tabla Usuarios
        // NOTA: No insertamos en 'Credenciales' manualmente porque la base de datos 
        // tiene un trigger que lo hace automáticamente al insertar en 'Usuarios'.
        await _supabase.client
            .schema('Usuarios')
            .from('Usuarios')
            .insert({
              'Nombre_Completo': nombre,
              'Correo_Electronico': correo,
              'Telefono': telefono,
              'Cedula': cedula,
              'Contrasena': contrasena,
              'rol': rol,
              'creado_por': creadoPor,
              'activo': true,
            });
      } catch (e) {
        print('❌ Error al insertar en Usuarios: $e');
        rethrow;
      }

      // 6. Retornar el objeto usuario construido manualmente con los datos que enviamos
      return Usuario(
        nombreCompleto: nombre,
        correoElectronico: correo,
        telefono: telefono,
        cedula: cedula,
        rol: rol,
        creadoPor: creadoPor,
        activo: true,
      );
    } catch (e) {
      print('❌ Error en crearUsuario: $e');
      rethrow;
    }
  }

  /// Editar rol de un usuario
  Future<void> editarRol(String usuarioId, String nuevoRol, {Map<String, dynamic>? configAsignacion}) async {
    try {
      final updates = {
        'rol': nuevoRol,
        if (configAsignacion != null) 'config_asignacion': configAsignacion,
      };

      await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .update(updates)
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

  /// Alias de compatibilidad — usado por widgets que necesitan lista completa
  Future<List<Usuario>> listarUsuarios() async {
    return getUsuarios();
  }

  /// Obtener la jerarquía de un administrador (él mismo + toda su descendencia de usuarios)
  Future<List<String>> getAdminTeam(String adminNombre) async {
    try {
      final users = await getUsuarios();
      Set<String> team = {adminNombre.trim().toLowerCase()};
      Set<String> teamOriginalNames = {adminNombre};
      
      bool added = true;
      while (added) {
        added = false;
        for (var u in users) {
          final creadorStr = (u.creadoPor ?? '').trim().toLowerCase();
          final nombreStr = u.nombreCompleto.trim().toLowerCase();
          
          if (creadorStr.isNotEmpty && team.contains(creadorStr) && !team.contains(nombreStr)) {
            team.add(nombreStr);
            teamOriginalNames.add(u.nombreCompleto);
            added = true;
          }
        }
      }
      return teamOriginalNames.toList();
    } catch (e) {
      print('❌ Error en getAdminTeam: $e');
      return [adminNombre];
    }
  }

  /// Eliminar un usuario permanentemente

  Future<void> eliminarUsuario(String usuarioId) async {
    try {
      await _supabase.client
          .schema('Usuarios')
          .from('Usuarios')
          .delete()
          .eq('id', usuarioId);
    } catch (e) {
      print('❌ Error en eliminarUsuario: $e');
      rethrow;
    }
  }
}
