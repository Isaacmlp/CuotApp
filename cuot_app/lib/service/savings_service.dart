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

  Future<void> updateGrupo(GrupoAhorro grupo) async {
    await _supabase.client
        .schema('Financiamientos')
        .from('Grupos_Ahorro')
        .update(grupo.toJson())
        .eq('id', grupo.id!);
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
    
    final String miembroId = resMiembro['id'].toString();

    try {
      // 2. Obtener datos del grupo para las fechas
      final grupo = await getGrupoById(miembro.grupoId);
      if (grupo == null) throw Exception('No se encontró el grupo');

      final int n = grupo.cantidadParticipantes;
      final DateTime startDate = grupo.fechaPrimerPago ?? grupo.fechaCreacion;
      final double montoCuota = miembro.montoCuota;

      // 3. Generar N cuotas SÓLO si el Susu ya inició
      if (grupo.fechaPrimerPago != null) {
        List<Map<String, dynamic>> cuotasJson = [];
        for (int i = 1; i <= n; i++) {
          // REGLA: El usuario que recibe no paga (la cuota se crea normal pero se bloqueará en la UI)
          bool pagadaActual = false;
          if (grupo.usuarioRecibeNoPaga == true && i == miembro.numeroTurno) {
            pagadaActual = true;
          }

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
            'pagada': pagadaActual,
          });
        }

        if (cuotasJson.isNotEmpty) {
          // 4. Insertar cuotas en bloque
          await _supabase.client
              .schema('Financiamientos')
              .from('Cuotas_Ahorro')
              .insert(cuotasJson);
        }
      }
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

  Future<void> deleteMiembro(String miembroId) async {
    try {
      // 1. Eliminar cuotas primero para evitar conflictos de integridad (si no hay cascade)
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas_Ahorro')
          .delete()
          .eq('miembro_id', miembroId);
      
      // 2. Eliminar el miembro
      await _supabase.client
          .schema('Financiamientos')
          .from('Miembros_Grupo')
          .delete()
          .eq('id', miembroId);
    } catch (e) {
      print('Error en deleteMiembro: $e');
      rethrow;
    }
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

  Future<List<Map<String, dynamic>>> getAportesGrupo(String grupoId) async {
    try {
      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Aportes_Grupo')
           // Seleccionamos datos del aporte y el nombre del miembro via join con Miembros y Clientes
          .select('*, Miembros_Grupo!inner(grupo_id, Clientes(nombre))')
          .eq('Miembros_Grupo.grupo_id', grupoId)
          .order('fecha_aporte', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error en getAportesGrupo: $e');
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
            .select('monto_pagado, monto_esperado, numero_cuota')
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

      // 4. Actualizar el total del grupo y recaudado_turno
      final grupoData = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select('total_acumulado, recaudado_turno, turno_actual')
          .eq('id', grupoId)
          .single();

      final double nuevoTotalGrupo =
          (grupoData['total_acumulado'] as num).toDouble() + aporte.monto;

      // REGLA: Sólo sumar a recaudado_turno si la cuota pagada pertenece al turno actual
      bool isCurrentTurn = true;
      if (cuotaId != null) {
        final cuotaData = await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas_Ahorro')
            .select('numero_cuota')
            .eq('id', cuotaId)
            .single();
        isCurrentTurn = cuotaData['numero_cuota'] == grupoData['turno_actual'];
      }

      final double nuevoRecaudadoTurno = isCurrentTurn
          ? ((grupoData['recaudado_turno'] ?? 0) as num).toDouble() + aporte.monto
          : ((grupoData['recaudado_turno'] ?? 0) as num).toDouble();

      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .update({
            'total_acumulado': nuevoTotalGrupo,
            'recaudado_turno': nuevoRecaudadoTurno,
          })
          .eq('id', grupoId);
    } catch (e) {
      print('Error en saveAporte: $e');
      rethrow;
    }
  }

  Future<void> entregarTurno(String grupoId) async {
    try {
      final grupoData = await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .select('turno_actual, recaudado_turno, total_acumulado, cantidad_participantes')
          .eq('id', grupoId)
          .single();

      final int turnoActual = (grupoData['turno_actual'] ?? 1);
      final double recaudadoTurnoAnterior = (grupoData['recaudado_turno'] ?? 0).toDouble();
      final double totalAcumuladoActual = (grupoData['total_acumulado'] ?? 0).toDouble();
      final int cantidadParticipantes = (grupoData['cantidad_participantes'] ?? 0);
      
      final int nuevoTurno = turnoActual + 1;
      
      // El nuevo total acumulado es el anterior menos lo que se entregó en este turno
      final double nuevoTotalAcumulado = (totalAcumuladoActual - recaudadoTurnoAnterior).clamp(0, double.infinity);

      // Calcular lo que ya se abonó por adelantado para este nuevoTurno:
      // Primero encontramos todos los miembros del grupo
      final miembros = await getMiembros(grupoId);
      final miembrosIds = miembros.map((e) => e.id!).toList();

      double totalAdelantado = 0;
      if (miembrosIds.isNotEmpty) {
        final cuotasAdelantadas = await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas_Ahorro')
            .select('monto_pagado')
            .inFilter('miembro_id', miembrosIds)
            .eq('numero_cuota', nuevoTurno);
            
        for (var row in cuotasAdelantadas) {
           totalAdelantado += (row['monto_pagado'] as num).toDouble();
        }
      }

      // Si el nuevo turno supera la cantidad de participantes, el grupo se finaliza
      final String nuevoEstado = nuevoTurno > cantidadParticipantes ? 'finalizado' : 'activo';

      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .update({
            'turno_actual': nuevoTurno > cantidadParticipantes ? cantidadParticipantes : nuevoTurno,
            'recaudado_turno': nuevoTurno > cantidadParticipantes ? 0 : totalAdelantado, 
            'total_acumulado': nuevoTotalAcumulado,
            'estado': nuevoEstado,
          })
          .eq('id', grupoId);
    } catch (e) {
      print('Error en entregarTurno: $e');
      rethrow;
    }
  }

  Future<void> intercambiarTurnos(MiembroGrupo m1, MiembroGrupo m2) async {
    try {
      final int? t1 = m1.numeroTurno;
      final int? t2 = m2.numeroTurno;

      // Usar un valor temporal negativo que garantice no chocar con turnos reales (ej. 1, 2, 3...)
      // ni con el valor 'null' (ya que pueden haber otros miembros sin turno).
      final int tempTurn = -9999;

      // Paso 1: Liberamos el turno de m1 pasándolo a un valor temporal
      await updateMiembro(m1.copyWith(numeroTurno: tempTurn));
      
      // Paso 2: Ahora el turno t1 está libre, pasamos m2 a t1
      await updateMiembro(m2.copyWith(numeroTurno: t1));
      
      // Paso 3: Ahora el turno t2 está libre, pasamos m1 a t2
      await updateMiembro(m1.copyWith(numeroTurno: t2));

    } catch (e) {
      print('Error en intercambiarTurnos: $e');
      // Intentar rollback en caso de error crítico si se quedó en el valor temporal
      try {
         await updateMiembro(m1.copyWith(numeroTurno: m1.numeroTurno));
      } catch (_) {}
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

  // --------------------------------------------------------------------------
  // INICIO DESFASADO DEL SUSU Y REASIGNACIÓN DE CUOTAS
  // --------------------------------------------------------------------------
  Future<void> iniciarSusu(String grupoId, DateTime fechaInicio) async {
    try {
      // 1. Obtener grupo y validar
      final grupo = await getGrupoById(grupoId);
      if (grupo == null) throw Exception('Grupo no encontrado');

      // 2. Establecer fecha de inicio en el backend
      await _supabase.client
          .schema('Financiamientos')
          .from('Grupos_Ahorro')
          .update({
            'fecha_primer_pago': fechaInicio.toIso8601String().split('T')[0]
          })
          .eq('id', grupoId);

      // 3. Obtener todos los miembros inscritos
      final miembros = await getMiembros(grupoId);
      if (miembros.isEmpty) return; // Nada que hacer

      // 4. Limpiar cualquier cuota "basura" existente de estos miembros
      final miembrosIds = miembros.map((e) => e.id!).toList();
      await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas_Ahorro')
          .delete()
          .inFilter('miembro_id', miembrosIds);

      // 5. Generar y asignar las cuotas organizadas
      List<Map<String, dynamic>> todasLasCuotas = [];
      final int n = grupo.cantidadParticipantes;

      for (var miembro in miembros) {
        for (int i = 1; i <= n; i++) {
          // REGLA: El usuario que recibe no paga (la cuota se crea normal pero se bloqueará en la UI)
          bool pagadaActual = false;
          if (grupo.usuarioRecibeNoPaga == true && i == miembro.numeroTurno) {
            pagadaActual = true;
          }

          DateTime fechaVencimiento;
          switch (grupo.periodo) {
            case PeriodoAhorro.diario:
              fechaVencimiento = fechaInicio.add(Duration(days: i - 1));
              break;
            case PeriodoAhorro.semanal:
              fechaVencimiento = fechaInicio.add(Duration(days: (i - 1) * 7));
              break;
            case PeriodoAhorro.quincenal:
              fechaVencimiento = fechaInicio.add(Duration(days: (i - 1) * 15));
              break;
            case PeriodoAhorro.mensual:
              fechaVencimiento = DateTime(fechaInicio.year, fechaInicio.month + (i - 1), fechaInicio.day);
              break;
          }

          todasLasCuotas.add({
            'miembro_id': miembro.id,
            'numero_cuota': i,
            'monto_esperado': miembro.montoCuota,
            'monto_pagado': 0,
            'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
            'pagada': pagadaActual,
          });
        }
      }

      if (todasLasCuotas.isNotEmpty) {
        await _supabase.client
            .schema('Financiamientos')
            .from('Cuotas_Ahorro')
            .insert(todasLasCuotas);
      }
    } catch (e) {
      print('Error al iniciar el susu y regenerar cuotas: $e');
      rethrow;
    }
  }
  
  Future<Map<String, double>> getStatsTurno(String grupoId, int turno) async {
    try {
      final grupo = await getGrupoById(grupoId);
      final bool usuarioRecibeNoPaga = grupo?.usuarioRecibeNoPaga ?? false;

      final miembros = await getMiembros(grupoId);
      final miembrosIds = miembros.map((e) => e.id!).toList();
      
      if (miembrosIds.isEmpty) return {'porCobrar': 0, 'cancelado': 0, 'total': 0, 'pendientesCount': 0};

      final response = await _supabase.client
          .schema('Financiamientos')
          .from('Cuotas_Ahorro')
          .select('miembro_id, monto_esperado, monto_pagado')
          .filter('miembro_id', 'in', '(${miembrosIds.map((id) => '"$id"').join(',')})')
          .eq('numero_cuota', turno);

      double porCobrar = 0;
      double cancelado = 0;
      double total = 0;
      int pendientesCount = 0;

      for (var row in response) {
        final mId = row['miembro_id'];
        // Buscar el miembro para saber si es su turno
        final miembro = miembros.where((m) => m.id == mId).firstOrNull;
        
        final bool isExenta = usuarioRecibeNoPaga && miembro != null && miembro.numeroTurno == turno;
        
        if (isExenta) continue; // No entra en las sumatorias

        final esperado = (row['monto_esperado'] as num).toDouble();
        final pagado = (row['monto_pagado'] as num).toDouble();
        total += esperado;
        cancelado += pagado;
        if (esperado - pagado > 0.01) {
          porCobrar += (esperado - pagado);
          pendientesCount++;
        }
      }

      return {
        'porCobrar': porCobrar,
        'cancelado': cancelado,
        'total': total,
        'pendientesCount': pendientesCount.toDouble(),
      };
    } catch (e) {
      print('Error en getStatsTurno: $e');
      return {'porCobrar': 0, 'cancelado': 0, 'total': 0};
    }
  }
}
