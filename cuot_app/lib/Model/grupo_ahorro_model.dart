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
  final int cantidadParticipantes;
  final DateTime? fechaPrimerPago;
  final String? descripcion; // Nota del objetivo

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
  };

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
