// lib/Model/cuota_personalizada.dart
/// Modelo que representa una cuota individual en el plan de pagos personalizado
class CuotaPersonalizada {
  /// Número de la cuota (1, 2, 3, etc.)
  final int numeroCuota;
  
  /// Fecha en que debe pagarse esta cuota
  DateTime fechaPago;
  
  /// Monto a pagar en esta cuota
  double monto;
  
  /// Estado de pago de la cuota
  bool pagada;
  
  /// Fecha en que realmente se pagó (si ya está pagada)
  DateTime? fechaPagoReal;

  CuotaPersonalizada({
    required this.numeroCuota,
    required this.fechaPago,
    required this.monto,
    this.pagada = false,
    this.fechaPagoReal,
  });

  /// Convierte el objeto a JSON para guardar en base de datos
  Map<String, dynamic> toJson() {
    return {
      'numeroCuota': numeroCuota,
      'fechaPago': fechaPago.toIso8601String(),
      'monto': monto,
      'pagada': pagada,
      'fechaPagoReal': fechaPagoReal?.toIso8601String(),
    };
  }

  /// Crea una instancia desde JSON (para recuperar de base de datos)
  factory CuotaPersonalizada.fromJson(Map<String, dynamic> json) {
    return CuotaPersonalizada(
      numeroCuota: json['numeroCuota'] ?? json['numero'] ?? 0, // Compatibilidad hacia atrás
      fechaPago: DateTime.parse(json['fechaPago']),
      monto: (json['monto'] as num).toDouble(),
      pagada: json['pagada'] ?? false,
      fechaPagoReal: json['fechaPagoReal'] != null 
          ? DateTime.parse(json['fechaPagoReal']) 
          : null,
    );
  }

  /// Formato legible de la fecha
  String get fechaFormateada => 
      '${fechaPago.day.toString().padLeft(2, '0')}/'
      '${fechaPago.month.toString().padLeft(2, '0')}/'
      '${fechaPago.year}';

  /// Copia el objeto con valores modificados (útil para actualizar)
  CuotaPersonalizada copyWith({
    int? numeroCuota,
    DateTime? fechaPago,
    double? monto,
    bool? pagada,
    DateTime? fechaPagoReal,
  }) {
    return CuotaPersonalizada(
      numeroCuota: numeroCuota ?? this.numeroCuota,
      fechaPago: fechaPago ?? this.fechaPago,
      monto: monto ?? this.monto,
      pagada: pagada ?? this.pagada,
      fechaPagoReal: fechaPagoReal ?? this.fechaPagoReal,
    );
  }

  static double calcularTotalCuotas(List<CuotaPersonalizada>? cuotas) {
    if (cuotas == null || cuotas.isEmpty) return 0;
    return cuotas.fold(0, (sum, cuota) => sum + cuota.monto);
  }

  /// Verifica si el total de cuotas coincide con el precio total
  static bool validarTotalCuotas(
    List<CuotaPersonalizada>? cuotas, 
    double precioTotalEsperado,
    {double tolerancia = 0.01} // Tolerancia para errores de redondeo
  ) {
    if (cuotas == null || cuotas.isEmpty) return false;
    final totalCalculado = calcularTotalCuotas(cuotas);
    return (totalCalculado - precioTotalEsperado).abs() <= tolerancia;
  }

  /// Obtiene la diferencia entre el total de cuotas y el precio esperado
  static double obtenerDiferenciaTotal(
    List<CuotaPersonalizada>? cuotas,
    double precioTotalEsperado,
  ) {
    if (cuotas == null || cuotas.isEmpty) return precioTotalEsperado;
    return calcularTotalCuotas(cuotas) - precioTotalEsperado;
  }

  @override
  String toString() {
    return 'Cuota #$numeroCuota: \$${monto.toStringAsFixed(2)} - $fechaFormateada ${pagada ? '(Pagada)' : ''}';
  }
}