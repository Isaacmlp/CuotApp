import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/Model/aporte_grupo_model.dart';
import 'package:cuot_app/Model/cliente_model.dart';

class SavingsService {
  final SupabaseService _supabase = SupabaseService();

  // --------------------------------------------------------------------------
  // GRUPOS
  // --------------------------------------------------------------------------

  Future<List<GrupoAhorro>> getGrupos(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select()
          .eq('creado_por', usuarioNombre)
          .order('fecha_creacion', ascending: false);
      
      return (response as List).map((json) => GrupoAhorro.fromJson(json)).toList();
    } catch (e) {
      print('Error en getGrupos: $e');
      return [];
    }
  }

  Future<GrupoAhorro?> getGrupoById(String id) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select()
          .eq('id', id)
          .single();
      
      return GrupoAhorro.fromJson(response);
    } catch (e) {
      print('Error en getGrupoById: $id -> $e');
      return null;
    }
  }

  Future<GrupoAhorro> createGrupo(GrupoAhorro grupo) async {
    final response = await _supabase.client
        .schema('Financiamientos')
        .from('Grupos_Ahorro')
        .insert(grupo.toJson())
        .select()
        .single();
    
    return GrupoAhorro.fromJson(response);
  }

  // --------------------------------------------------------------------------
  // MIEMBROS
  // --------------------------------------------------------------------------

  Future<List<MiembroGrupo>> getMiembros(String grupoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .select('*, Clientes(*)')
          .eq('grupo_id', grupoId);
      
      return (response as List).map((json) => MiembroGrupo.fromJson(json)).toList();
    } catch (e) {
      print('Error en getMiembros: $e');
      return [];
    }
  }

  Future<void> addMiembro(MiembroGrupo miembro) async {
    await _supabase.client
        .schema('Financiamientos')
        .from('Miembros_Grupo')
        .insert(miembro.toJson());
  }

  // --------------------------------------------------------------------------
  // APORTES
  // --------------------------------------------------------------------------

  Future<List<AporteGrupo>> getAportes(String miembroId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Aportes_Grupo')
          .select()
          .eq('miembro_id', miembroId)
          .order('fecha_aporte', ascending: false);
      
      return (response as List).map((json) => AporteGrupo.fromJson(json)).toList();
    } catch (e) {
      print('Error en getAportes: $e');
      return [];
    }
  }

  Future<void> saveAporte(AporteGrupo aporte) async {
    try {
      // 1. Insertar el aporte
      await _supabase.client
          .schema('Financiamientos')
          .from('Aportes_Grupo')
          .insert(aporte.toJson());

      // 2. Actualizar el total del miembro
      final miembroData = await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .select('total_aportado, grupo_id')
          .eq('id', aporte.miembroId)
          .single();
      
      final double nuevoTotalMiembro = (miembroData['total_aportado'] as num).toDouble() + aporte.monto;
      final String grupoId = miembroData['grupo_id'];

      await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .update({'total_aportado': nuevoTotalMiembro})
          .eq('id', aporte.miembroId);

      // 3. Actualizar el total del grupo
      final grupoData = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select('total_acumulado')
          .eq('id', grupoId)
          .single();
      
      final double nuevoTotalGrupo = (grupoData['total_acumulado'] as num).toDouble() + aporte.monto;

      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .update({'total_acumulado': nuevoTotalGrupo})
          .eq('id', grupoId);
          
    } catch (e) {
      print('Error en saveAporte: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CLIENTES (Auxiliar para miembros)
  // --------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchClientes(String query, String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Clientes')
          .select()
          .eq('usuario_nombre', usuarioNombre)
          .ilike('nombre', '%$query%')
          .limit(10);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en searchClientes: $e');
      return [];
    }
  }

  Future<String> createCliente(String nombre, String telefono, String usuarioNombre) async {
    final response = await _supabase.client
        .schema('Financiamientos')
        .from('Clientes')
        .insert({
          'nombre': nombre,
          'telefono': telefono,
          'usuario_nombre': usuarioNombre,
        })
        .select('id')
        .single();
    
    return response['id'].toString();
  }
}
