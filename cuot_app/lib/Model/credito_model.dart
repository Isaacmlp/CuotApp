enum TipoCredito { cuotas, unPago }
enum ModalidadPago { diario, semanal, quincenal, mensual, personalizado }

class Credito {
  String? id;
  String concepto;
  double costeInversion;
  double margenGanancia;
  DateTime fechaInicio;
  ModalidadPago modalidadPago;
  String nombreCliente;
  // 🔧 NUEVOS CAMPOS
  final String? facturaPath;
  final String? nombreFactura;
  // Para créditos en cuotas
  int? numeroCuotas;
  List<Cuota>? cuotasPersonalizadas;
  
  // Campos calculados
  double get precioTotal => costeInversion + margenGanancia;
  double? get valorCuota {
    if (numeroCuotas == null || numeroCuotas == 0) return null;
    return precioTotal / numeroCuotas!;
  }

  Credito({
    this.id,
    required this.concepto,
    required this.costeInversion,
    required this.margenGanancia,
    required this.fechaInicio,
    required this.modalidadPago,
    required this.nombreCliente,
    this.numeroCuotas,
    this.cuotasPersonalizadas,
    this.facturaPath,
    this.nombreFactura,
  });
}

class Cuota {
  int numero;
  DateTime fechaPago;
  double monto;
  bool pagada;

  Cuota({
    required this.numero,
    required this.fechaPago,
    required this.monto,
    this.pagada = false,
  });
}