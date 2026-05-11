// lib/Model/pago_model.dart
import 'package:cuot_app/utils/date_utils.dart';

class Pago {
  final String id;
  final String creditoId;
  final int numeroCuota;
  final DateTime fechaPago;
  final double monto;
  final DateTime? fechaPagoReal;
  final String estado; // 'pendiente', 'pagado', 'atrasado'
  final String? metodoPago; // 'efectivo', 'transferencia', 'tarjeta'
  final String? referencia;
  final String? observaciones;
  final String? comprobantePath; // 👈 NUEVO: Ruta local del capture

  Pago({
    required this.id,
    required this.creditoId,
    required this.numeroCuota,
    required this.fechaPago,
    required this.monto,
    this.fechaPagoReal,
    this.estado = 'pendiente',
    this.metodoPago,
    this.referencia,
    this.observaciones,
    this.comprobantePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditoId': creditoId,
      'numeroCuota': numeroCuota,
      'fechaPago': fechaPago.toUtc().toIso8601String(),
      'monto': monto,
      'fechaPagoReal': fechaPagoReal?.toUtc().toIso8601String(),
      'estado': estado,
      'metodoPago': metodoPago,
      'referencia': referencia,
      'observaciones': observaciones,
      'comprobantePath': comprobantePath,
    };
  }

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'].toString(),
      creditoId: json['creditoId'].toString(),
      numeroCuota: json['numeroCuota'],
      fechaPago: DateUt.parsePureDate(json['fechaPago']),
      monto: (json['monto'] as num).toDouble(),
      fechaPagoReal: json['fechaPagoReal'] != null 
          ? DateUt.parsePureDate(json['fechaPagoReal']) 
          : null,
      estado: json['estado'] ?? 'pendiente',
      metodoPago: json['metodoPago'],
      referencia: json['referencia'],
      observaciones: json['observaciones'],
      comprobantePath: json['comprobantePath'],
    );
  }

  Pago copyWith({
    String? id,
    String? creditoId,
    int? numeroCuota,
    DateTime? fechaPago,
    double? monto,
    DateTime? fechaPagoReal,
    String? estado,
    String? metodoPago,
    String? referencia,
    String? observaciones,
    String? comprobantePath,
  }) {
    return Pago(
      id: id ?? this.id,
      creditoId: creditoId ?? this.creditoId,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      fechaPago: fechaPago ?? this.fechaPago,
      monto: monto ?? this.monto,
      fechaPagoReal: fechaPagoReal ?? this.fechaPagoReal,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
      referencia: referencia ?? this.referencia,
      observaciones: observaciones ?? this.observaciones,
      comprobantePath: comprobantePath ?? this.comprobantePath,
    );
  }

  String get fechaFormateada => 
      '${fechaPago.day.toString().padLeft(2, '0')}/'
      '${fechaPago.month.toString().padLeft(2, '0')}/'
      '${fechaPago.year}';

  bool get estaPagado => estado == 'pagado';
  bool get estaAtrasado => estado == 'atrasado' && !estaPagado;
}