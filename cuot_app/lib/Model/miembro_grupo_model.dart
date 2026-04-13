import 'package:cuot_app/utils/date_utils.dart';

class MiembroGrupo {
  final String? id;
  final String grupoId;
  final String clienteId;
  final String? nombreCliente; // Para UI
  final double montoMetaPersonal;
  final double totalAportado;
  final DateTime fechaIngreso;

  MiembroGrupo({
    this.id,
    required this.grupoId,
    required this.clienteId,
    this.nombreCliente,
    this.montoMetaPersonal = 0,
    this.totalAportado = 0,
    required this.fechaIngreso,
  });

  factory MiembroGrupo.fromJson(Map<String, dynamic> json) {
    return MiembroGrupo(
      id: json['id'],
      grupoId: json['grupo_id'],
      clienteId: json['cliente_id'],
      nombreCliente: json['Clientes'] != null ? json['Clientes']['nombre'] : null,
      montoMetaPersonal: (json['monto_meta_personal'] as num).toDouble(),
      totalAportado: (json['total_aportado'] as num).toDouble(),
      fechaIngreso: DateUt.parsePureDate(json['fecha_ingreso']),
    );
  }

  Map<String, dynamic> toJson() => {
    'grupo_id': grupoId,
    'cliente_id': clienteId,
    'monto_meta_personal': montoMetaPersonal,
    'total_aportado': totalAportado,
    'fecha_ingreso': fechaIngreso.toIso8601String(),
  };

  double get progreso => montoMetaPersonal > 0 ? totalAportado / montoMetaPersonal : 0;
}
