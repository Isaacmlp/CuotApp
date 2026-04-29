import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';

class AhorroTurnoInfo {
  final int turnoActual;
  final String nombreProximo;
  final int diasRestantes;
  final DateTime fechaProxima;

  AhorroTurnoInfo({
    required this.turnoActual,
    required this.nombreProximo,
    required this.diasRestantes,
    required this.fechaProxima,
  });
}

class AhorroLogicHelper {
  static AhorroTurnoInfo getTurnoInformacion(
    GrupoAhorro grupo,
    List<MiembroGrupo> miembros,
  ) {
    if (miembros.isEmpty) {
      return AhorroTurnoInfo(
        turnoActual: 1,
        nombreProximo: 'Sin miembros',
        diasRestantes: 0,
        fechaProxima: grupo.fechaPrimerPago ?? grupo.fechaCreacion,
      );
    }

    final DateTime now = DateTime.now();
    final DateTime startDate = grupo.fechaPrimerPago ?? grupo.fechaCreacion;
    
    // El turno real es el que dicta la base de datos
    int turnoActual = grupo.turnoActual;
    
    // Calcular fecha del próximo turno (el que está en progreso)
    DateTime fechaProxima;
    switch (grupo.periodo) {
      case PeriodoAhorro.diario:
        fechaProxima = startDate.add(Duration(days: turnoActual - 1));
        break;
      case PeriodoAhorro.semanal:
        fechaProxima = startDate.add(Duration(days: (turnoActual - 1) * 7));
        break;
      case PeriodoAhorro.quincenal:
        fechaProxima = startDate.add(Duration(days: (turnoActual - 1) * 15));
        break;
      case PeriodoAhorro.mensual:
        fechaProxima = DateTime(startDate.year, startDate.month + (turnoActual - 1), startDate.day);
        break;
    }

    int diasRestantes = fechaProxima.difference(now).inDays;
    if (diasRestantes < 0) diasRestantes = 0;

    // Buscar quién tiene ese turno
    String nombre = 'Turno $turnoActual libre';
    if (turnoActual > grupo.cantidadParticipantes) {
      nombre = 'Ciclos completados';
    } else {
      final m = miembros.where((m) => m.numeroTurno == turnoActual).firstOrNull;
      if (m != null) {
        nombre = m.nombreCliente ?? 'N/A';
      }
    }

    return AhorroTurnoInfo(
      turnoActual: turnoActual,
      nombreProximo: nombre,
      diasRestantes: diasRestantes,
      fechaProxima: fechaProxima,
    );
  }
}
