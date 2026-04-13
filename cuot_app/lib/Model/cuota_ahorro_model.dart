import 'package:cuot_app/utils/date_utils.dart';

class CuotaAhorro {
  final String? id;
  final String miembroId;
  final int numeroCuota;
  final double montoEsperado;
  final double montoPagado;
  final DateTime fechaVencimiento;
  final bool pagada;

  CuotaAhorro({
    this.id,
    required this.miembroId,
    required this.numeroCuota,
    required this.montoEsperado,
    this.montoPagado = 0,
    required this.fechaVencimiento,
    this.pagada = false,
  });

  factory CuotaAhorro.fromJson(Map<String, dynamic> json) {
    return CuotaAhorro(
      id: json['id'],
      miembroId: json['miembro_id'],
      numeroCuota: json['numero_cuota'],
      montoEsperado: (json['monto_esperado'] as num).toDouble(),
      montoPagado: (json['monto_pagado'] as num).toDouble(),
      fechaVencimiento: DateUt.parsePureDate(json['fecha_vencimiento']),
      pagada: json['pagada'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'miembro_id': miembroId,
    'numero_cuota': numeroCuota,
    'monto_esperado': montoEsperado,
    'monto_pagado': montoPagado,
    'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
    'pagada': pagada,
  };

  double get pendiente => montoEsperado - montoPagado;
}
