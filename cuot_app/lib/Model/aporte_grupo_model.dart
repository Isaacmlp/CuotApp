import 'package:cuot_app/utils/date_utils.dart';

class AporteGrupo {
  final String? id;
  final String miembroId;
  final double monto;
  final DateTime fechaAporte;
  final String metodoPago;
  final String? referencia;
  final String? observaciones;
  final String? comprobantePath; // 👈 NUEVO
  final String? adminResponsable; // 👈 NUEVO
  final String? estadoVerificacion; // 👈 NUEVO

  AporteGrupo({
    this.id,
    required this.miembroId,
    required this.monto,
    required this.fechaAporte,
    this.metodoPago = 'efectivo',
    this.referencia,
    this.observaciones,
    this.comprobantePath,
    this.adminResponsable,
    this.estadoVerificacion,
  });

  factory AporteGrupo.fromJson(Map<String, dynamic> json) {
    return AporteGrupo(
      id: json['id'],
      miembroId: json['miembro_id'],
      monto: (json['monto'] as num).toDouble(),
      fechaAporte: DateUt.parsePureDate(json['fecha_aporte']),
      metodoPago: json['metodo_pago'] ?? 'efectivo',
      referencia: json['referencia'],
      observaciones: json['observaciones'],
      comprobantePath: json['comprobante_path'],
      adminResponsable: json['admin_responsable'],
      estadoVerificacion: json['estado_verificacion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'miembro_id': miembroId,
    'monto': monto,
    'fecha_aporte': fechaAporte.toUtc().toIso8601String(),
    'metodo_pago': metodoPago,
    'referencia': referencia,
    'observaciones': observaciones,
    'comprobante_path': comprobantePath,
    'admin_responsable': adminResponsable,
    'estado_verificacion': estadoVerificacion,
  };
}
