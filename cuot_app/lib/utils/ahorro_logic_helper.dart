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
    
    // Calcular cuántos periodos han pasado desde la fecha de inicio
    int periodosPasados = 0;
    int diasDesdeInicio = now.difference(startDate).inDays;

    if (now.isBefore(startDate)) {
      // Aún no ha empezado el ciclo
      periodosPasados = 0;
    } else {
      switch (grupo.periodo) {
        case PeriodoAhorro.diario:
          periodosPasados = diasDesdeInicio;
          break;
        case PeriodoAhorro.semanal:
          periodosPasados = (diasDesdeInicio / 7).floor();
          break;
        case PeriodoAhorro.quincenal:
          periodosPasados = (diasDesdeInicio / 15).floor();
          break;
        case PeriodoAhorro.mensual:
          // Aproximación mensual: diferencia en meses
          periodosPasados = (now.year - startDate.year) * 12 + now.month - startDate.month;
          if (now.day < startDate.day) periodosPasados--;
          break;
      }
    }

    int turnoActual = periodosPasados + 1;
    
    // Calcular fecha del próximo turno
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

    // Si la fecha calculada ya pasó, el próximo turno es el siguiente
    if (now.isAfter(fechaProxima.add(const Duration(days: 1)))) {
       // Opcional: Podrías avanzar el turno aquí si consideras que el turno se "ejecuta" el mismo día
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
