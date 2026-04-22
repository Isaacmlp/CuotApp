import 'package:cuot_app/utils/date_utils.dart';

enum TipoAporte { comun, diferente }
enum PeriodoAhorro { diario, semanal, quincenal, mensual }
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
  final DateTime? fechaPrimerPago;
  final String? descripcion; // Nota del objetivo
  final int cantidadParticipantes;
  final int turnoActual; // Turno en curso
  final double recaudadoTurno; // Lo recaudado solo para el turno actual
  final bool usuarioRecibeNoPaga;

  GrupoAhorro({
    this.id,
    required this.nombre,
    required this.metaAhorro,
    this.tipoAporte = TipoAporte.comun,
    required this.periodo,
    this.totalAcumulado = 0,
    required this.creadoPor,
    required this.fechaCreacion,
    this.estado = EstadoGrupo.activo,
    required this.cantidadParticipantes,
    this.fechaPrimerPago,
    this.descripcion,
    this.turnoActual = 1,
    this.recaudadoTurno = 0,
    this.usuarioRecibeNoPaga = false,
  });

  factory GrupoAhorro.fromJson(Map<String, dynamic> json) {
    return GrupoAhorro(
      id: json['id'],
      nombre: json['nombre'],
      metaAhorro: (json['meta_ahorro'] as num).toDouble(),
      tipoAporte: json['tipo_aporte'] == 'diferente' ? TipoAporte.diferente : TipoAporte.comun,
      periodo: _parsePeriodo(json['periodo']),
      totalAcumulado: (json['total_acumulado'] as num).toDouble(),
      creadoPor: json['creado_por'],
      fechaCreacion: DateUt.parsePureDate(json['fecha_creacion']),
      estado: _parseEstado(json['estado']),
      cantidadParticipantes: json['cantidad_participantes'] ?? 0,
      fechaPrimerPago: json['fecha_primer_pago'] != null ? DateUt.parsePureDate(json['fecha_primer_pago']) : null,
      descripcion: json['descripcion'],
      turnoActual: json['turno_actual'] ?? 1,
      recaudadoTurno: (json['recaudado_turno'] as num?)?.toDouble() ?? 0,
      usuarioRecibeNoPaga: json['usuario_recibe_no_paga'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'meta_ahorro': metaAhorro,
    'tipo_aporte': tipoAporte == TipoAporte.diferente ? 'diferente' : 'comun',
    'periodo': periodo.name,
    'total_acumulado': totalAcumulado,
    'creado_por': creadoPor,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'estado': estado.name,
    'cantidad_participantes': cantidadParticipantes,
    'fecha_primer_pago': fechaPrimerPago?.toIso8601String().split('T')[0],
    'descripcion': descripcion,
    'turno_actual': turnoActual,
    'recaudado_turno': recaudadoTurno,
    'usuario_recibe_no_paga': usuarioRecibeNoPaga,
  };

  GrupoAhorro copyWith({
    String? id,
    String? nombre,
    double? metaAhorro,
    TipoAporte? tipoAporte,
    PeriodoAhorro? periodo,
    double? totalAcumulado,
    String? creadoPor,
    DateTime? fechaCreacion,
    EstadoGrupo? estado,
    DateTime? fechaPrimerPago,
    String? descripcion,
    int? cantidadParticipantes,
    int? turnoActual,
    double? recaudadoTurno,
    bool? usuarioRecibeNoPaga,
  }) {
    return GrupoAhorro(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      metaAhorro: metaAhorro ?? this.metaAhorro,
      tipoAporte: tipoAporte ?? this.tipoAporte,
      periodo: periodo ?? this.periodo,
      totalAcumulado: totalAcumulado ?? this.totalAcumulado,
      creadoPor: creadoPor ?? this.creadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estado: estado ?? this.estado,
      cantidadParticipantes: cantidadParticipantes ?? this.cantidadParticipantes,
      fechaPrimerPago: fechaPrimerPago ?? this.fechaPrimerPago,
      descripcion: descripcion ?? this.descripcion,
      turnoActual: turnoActual ?? this.turnoActual,
      recaudadoTurno: recaudadoTurno ?? this.recaudadoTurno,
      usuarioRecibeNoPaga: usuarioRecibeNoPaga ?? this.usuarioRecibeNoPaga,
    );
  }

  static PeriodoAhorro _parsePeriodo(String? value) {
    if (value == null) return PeriodoAhorro.semanal;
    switch (value.toLowerCase()) {
      case 'diario': return PeriodoAhorro.diario;
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
