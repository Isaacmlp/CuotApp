import 'package:cuot_app/utils/date_utils.dart';

class MiembroGrupo {
  final String? id;
  final String grupoId;
  final String clienteId;
  final String? nombreCliente; // Para UI
  final String? telefonoCliente; // Para WhatsApp directo
  final double montoMetaPersonal;
  final double totalAportado;
  final DateTime fechaIngreso;
  final String? articuloDeseado;
  final int? numeroTurno;
  final double montoCuota;

  MiembroGrupo({
    this.id,
    required this.grupoId,
    required this.clienteId,
    this.nombreCliente,
    this.telefonoCliente,
    this.montoMetaPersonal = 0,
    this.totalAportado = 0,
    required this.fechaIngreso,
    this.articuloDeseado,
    this.numeroTurno,
    this.montoCuota = 0,
  });

  factory MiembroGrupo.fromJson(Map<String, dynamic> json) {
    return MiembroGrupo(
      id: json['id'],
      grupoId: json['grupo_id'],
      clienteId: json['cliente_id'],
      nombreCliente: json['Clientes'] != null ? json['Clientes']['nombre'] : null,
      telefonoCliente: json['Clientes'] != null ? json['Clientes']['telefono'] : null,
      montoMetaPersonal: (json['monto_meta_personal'] as num).toDouble(),
      totalAportado: (json['total_aportado'] as num).toDouble(),
      fechaIngreso: DateUt.parsePureDate(json['fecha_ingreso']),
      articuloDeseado: json['notas_compra'],
      numeroTurno: json['numero_turno'] != null ? json['numero_turno'] as int : null,
      montoCuota: json['monto_cuota'] != null ? (json['monto_cuota'] as num).toDouble() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'grupo_id': grupoId,
    'cliente_id': clienteId,
    'monto_meta_personal': montoMetaPersonal,
    'total_aportado': totalAportado,
    'fecha_ingreso': fechaIngreso.toIso8601String(),
    if (articuloDeseado != null) 'notas_compra': articuloDeseado,
    if (numeroTurno != null) 'numero_turno': numeroTurno,
    'monto_cuota': montoCuota,
  };

  double get progreso => montoMetaPersonal > 0 ? totalAportado / montoMetaPersonal : 0;

  MiembroGrupo copyWith({
    String? id,
    String? grupoId,
    String? clienteId,
    String? nombreCliente,
    String? telefonoCliente,
    double? montoMetaPersonal,
    double? totalAportado,
    DateTime? fechaIngreso,
    String? articuloDeseado,
    int? numeroTurno,
    double? montoCuota,
  }) {
    return MiembroGrupo(
      id: id ?? this.id,
      grupoId: grupoId ?? this.grupoId,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      montoMetaPersonal: montoMetaPersonal ?? this.montoMetaPersonal,
      totalAportado: totalAportado ?? this.totalAportado,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      articuloDeseado: articuloDeseado ?? this.articuloDeseado,
      numeroTurno: numeroTurno ?? this.numeroTurno,
      montoCuota: montoCuota ?? this.montoCuota,
    );
  }
}
