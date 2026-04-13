import 'package:cuot_app/utils/date_utils.dart';

enum TipoAporte { comun, diferente }
enum PeriodoAhorro { semanal, quincenal, mensual }
enum EstadoGrupo { activo, finalizado, cancelado }

class GrupoAhorro {
  final String? id;
  final String nombre;
  final double metaAhorro;
  final TipoAporte tipoAporte;
  final PeriodoAhorro periodo;
  final double totalAcumulado;
  final String creadoPor;
  final DateTime fechaCreacion;
  final EstadoGrupo estado;
  final int cantidadParticipantes;

  GrupoAhorro({
    this.id,
    required this.nombre,
    required this.metaAhorro,
    required this.tipoAporte,
    required this.periodo,
    this.totalAcumulado = 0,
    required this.creadoPor,
    required this.fechaCreacion,
    this.estado = EstadoGrupo.activo,
    required this.cantidadParticipantes,
  });

  factory GrupoAhorro.fromJson(Map<String, dynamic> json) {
    return GrupoAhorro(
      id: json['id'],
      nombre: json['nombre'],
      metaAhorro: (json['meta_ahorro'] as num).toDouble(),
      tipoAporte: json['tipo_aporte'] == 'comun' ? TipoAporte.comun : TipoAporte.diferente,
      periodo: _parsePeriodo(json['periodo']),
      totalAcumulado: (json['total_acumulado'] as num).toDouble(),
      creadoPor: json['creado_por'],
      fechaCreacion: DateUt.parsePureDate(json['fecha_creacion']),
      estado: _parseEstado(json['estado']),
      cantidadParticipantes: json['cantidad_participantes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'meta_ahorro': metaAhorro,
    'tipo_aporte': tipoAporte == TipoAporte.comun ? 'comun' : 'diferente',
    'periodo': periodo.name,
    'total_acumulado': totalAcumulado,
    'creado_por': creadoPor,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'estado': estado.name,
    'cantidad_participantes': cantidadParticipantes,
  };

  static PeriodoAhorro _parsePeriodo(String value) {
    switch (value.toLowerCase()) {
      case 'semanal': return PeriodoAhorro.semanal;
      case 'quincenal': return PeriodoAhorro.quincenal;
      case 'mensual': return PeriodoAhorro.mensual;
      default: return PeriodoAhorro.semanal;
    }
  }

  static EstadoGrupo _parseEstado(String value) {
    switch (value.toLowerCase()) {
      case 'activo': return EstadoGrupo.activo;
      case 'finalizado': return EstadoGrupo.finalizado;
      case 'cancelado': return EstadoGrupo.cancelado;
      default: return EstadoGrupo.activo;
    }
  }
}
