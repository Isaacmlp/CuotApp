import 'package:cuot_app/utils/date_utils.dart';

class AporteGrupo {
  final String? id;
  final String miembroId;
  final double monto;
  final DateTime fechaAporte;
  final String metodoPago;
  final String? referencia;
  final String? observaciones;

  AporteGrupo({
    this.id,
    required this.miembroId,
    required this.monto,
    required this.fechaAporte,
    this.metodoPago = 'efectivo',
    this.referencia,
    this.observaciones,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'miembro_id': miembroId,
    'monto': monto,
    'fecha_aporte': fechaAporte.toIso8601String(),
    'metodo_pago': metodoPago,
    'referencia': referencia,
    'observaciones': observaciones,
  };
}
