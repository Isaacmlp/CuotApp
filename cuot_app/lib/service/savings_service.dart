import 'package:cuot_app/core/supabase/supabase_service.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/Model/aporte_grupo_model.dart';
import 'package:cuot_app/Model/cliente_model.dart';
import 'package:cuot_app/Model/cuota_ahorro_model.dart';

class SavingsService {
  final SupabaseService _supabase = SupabaseService();

  // --------------------------------------------------------------------------
  // GRUPOS
  // --------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getGruposConMiembros(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select('*, Miembros_Grupo(*, Clientes(*))')
          .eq('creado_por', usuarioNombre)
          .order('fecha_creacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getGruposConMiembros: $e');
      return [];
    }
  }

  Future<List<GrupoAhorro>> getGrupos(String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select()
          .eq('creado_por', usuarioNombre)
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => GrupoAhorro.fromJson(json))
          .toList();
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

  Future<void> deleteGrupo(String id) async {
    try {
      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error al eliminar grupo $id: $e');
      rethrow;
    }
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

      return (response as List)
          .map((json) => MiembroGrupo.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en getMiembros: $e');
      return [];
    }
  }

  Future<void> addMiembro(MiembroGrupo miembro) async {
    // 1. Insertar el Miembro y obtener su ID
    final resMiembro = await _supabase.client
        .schema('Financiamientos')
        .from('Miembros_Grupo')
        .insert(miembro.toJson())
        .select()
        .single();
    
    final String miembroId = resMiembro['id'];

    try {
      // 2. Obtener datos del grupo para las fechas
      final grupo = await getGrupoById(miembro.grupoId);
      if (grupo == null) throw Exception('No se encontró el grupo');

      final int n = grupo.cantidadParticipantes;
      final DateTime startDate = grupo.fechaPrimerPago ?? grupo.fechaCreacion;
      final double montoCuota = miembro.montoCuota;

      // 3. Generar N cuotas
      List<Map<String, dynamic>> cuotasJson = [];
      for (int i = 1; i <= n; i++) {
        DateTime fechaVencimiento;
        switch (grupo.periodo) {
          case PeriodoAhorro.diario:
            fechaVencimiento = startDate.add(Duration(days: i - 1));
            break;
          case PeriodoAhorro.semanal:
            fechaVencimiento = startDate.add(Duration(days: (i - 1) * 7));
            break;
          case PeriodoAhorro.quincenal:
            fechaVencimiento = startDate.add(Duration(days: (i - 1) * 15));
            break;
          case PeriodoAhorro.mensual:
            fechaVencimiento =
                DateTime(startDate.year, startDate.month + (i - 1), startDate.day);
            break;
        }

        cuotasJson.add({
          'miembro_id': miembroId,
          'numero_cuota': i,
          'monto_esperado': montoCuota,
          'monto_pagado': 0,
          'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
          'pagada': false,
        });
      }

      // 4. Insertar cuotas en bloque
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas_Ahorro')
          .insert(cuotasJson);
    } catch (e) {
      // 5. ROLLBACK MANUAL: Si fallan las cuotas, borramos al miembro para no dejar basura
      print('Fallo al crear cuotas, borrando miembro $miembroId: $e');
      await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .delete()
          .eq('id', miembroId);
      rethrow;
    }
  }

  Future<List<CuotaAhorro>> getCuotasMiembro(String miembroId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas_Ahorro')
          .select()
          .eq('miembro_id', miembroId)
          .order('numero_cuota', ascending: true);
      
      return (response as List).map((json) => CuotaAhorro.fromJson(json)).toList();
    } catch (e) {
      print('Error en getCuotasMiembro: $e');
      return [];
    }
  }

  Future<void> updateMiembro(MiembroGrupo miembro) async {
    await _supabase.client
        .schema('Financiamientos')
        .from('Miembros_Grupo')
        .update(miembro.toJson())
        .eq('id', miembro.id!);
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

      return (response as List)
          .map((json) => AporteGrupo.fromJson(json))
          .toList();
    } catch (e) {
      print('Error en getAportes: $e');
      return [];
    }
  }

  Future<void> saveAporte(AporteGrupo aporte, {String? cuotaId}) async {
    try {
      // 1. Insertar el aporte
      await _supabase.client
          .schema('Financiamientos')
          .from('Aportes_Grupo')
          .insert(aporte.toJson());

      // 2. Si hay cuotaId, actualizar la cuota
      if (cuotaId != null) {
        final cuotaData = await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas_Ahorro')
            .select('monto_pagado, monto_esperado')
            .eq('id', cuotaId)
            .single();
        
        final double nuevoPagado = (cuotaData['monto_pagado'] as num).toDouble() + aporte.monto;
        final double esperado = (cuotaData['monto_esperado'] as num).toDouble();
        
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas_Ahorro')
            .update({
              'monto_pagado': nuevoPagado,
              'pagada': nuevoPagado >= (esperado - 0.01),
            })
            .eq('id', cuotaId);
      }

      // 3. Actualizar el total del miembro
      final miembroData = await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .select('total_aportado, grupo_id')
          .eq('id', aporte.miembroId)
          .single();

      final double nuevoTotalMiembro =
          (miembroData['total_aportado'] as num).toDouble() + aporte.monto;
      final String grupoId = miembroData['grupo_id'];

      await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .update({'total_aportado': nuevoTotalMiembro}).eq(
              'id', aporte.miembroId);

      // 4. Actualizar el total del grupo
      final grupoData = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select('total_acumulado')
          .eq('id', grupoId)
          .single();

      final double nuevoTotalGrupo =
          (grupoData['total_acumulado'] as num).toDouble() + aporte.monto;

      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .update({'total_acumulado': nuevoTotalGrupo}).eq('id', grupoId);
    } catch (e) {
      print('Error en saveAporte: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // CLIENTES (Auxiliar para miembros)
  // --------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchClientes(
      String query, String usuarioNombre) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Clientes')
          .select()
          .eq('usuario_creador', usuarioNombre)
          .ilike('nombre', '%$query%')
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en searchClientes: $e');
      return [];
    }
  }

  Future<String> createCliente(
      String nombre, String telefono, String usuarioNombre) async {
    final response = await _supabase.client
        .schema('Financiamientos')
        .from('Clientes')
        .insert({
          'nombre': nombre,
          'telefono': telefono,
          'usuario_creador': usuarioNombre,
        })
        .select('id')
        .single();

    return response['id'].toString();
  }
}
