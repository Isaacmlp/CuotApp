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
      'credito_id': creditoId,
      'numero_cuota': numeroCuota,
      'fecha_pago': fechaPago.toUtc().toIso8601String(),
      'monto': monto,
      'fecha_pago_real': fechaPagoReal?.toUtc().toIso8601String(),
      'estado': estado,
      'metodo_pago': metodoPago,
      'referencia': referencia,
      'observaciones': observaciones,
      'comprobante_path': comprobantePath,
    };
  }

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'].toString(),
      creditoId: (json['credito_id'] ?? json['creditoId']).toString(),
      numeroCuota: json['numero_cuota'] ?? json['numeroCuota'],
      fechaPago: DateUt.parsePureDate(json['fecha_pago'] ?? json['fechaPago']),
      monto: (json['monto'] as num).toDouble(),
      fechaPagoReal: (json['fecha_pago_real'] ?? json['fechaPagoReal']) != null 
          ? DateUt.parsePureDate(json['fecha_pago_real'] ?? json['fechaPagoReal']) 
          : null,
      estado: json['estado'] ?? 'pendiente',
      metodoPago: json['metodo_pago'] ?? json['metodoPago'],
      referencia: json['referencia'],
      observaciones: json['observaciones'],
      comprobantePath: json['comprobante_path'] ?? json['comprobantePath'],
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