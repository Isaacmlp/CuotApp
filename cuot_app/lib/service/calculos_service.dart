// 🧮 LÓGICA DE NEGOCIO: Cálculos y validaciones
import 'package:cuot_app/Model/credito_model.dart';

class CalculosService {
  
  // Calcular el valor de cada cuota según modalidad
  static List<Cuota> calcularCalendarioPagos({
    required DateTime fechaInicio,
    required double montoTotal,
    required int numeroCuotas,
    required ModalidadPago modalidad,
  }) {
    List<Cuota> cuotas = [];
    DateTime fechaActual = fechaInicio;
    double valorCuota = montoTotal / numeroCuotas;
    
    for (int i = 1; i <= numeroCuotas; i++) {
      // Calcular próxima fecha según modalidad
      DateTime fechaPago = _calcularSiguienteFecha(fechaActual, modalidad);
      
      cuotas.add(Cuota(
        numero: i,
        fechaPago: fechaPago,
        monto: valorCuota,
      ));
      
      fechaActual = fechaPago;
    }
    
    return cuotas;
  }
  
  static DateTime _calcularSiguienteFecha(DateTime fecha, ModalidadPago modalidad) {
    switch (modalidad) {
      case ModalidadPago.diario:
        return fecha.add(Duration(days: 1));
      case ModalidadPago.semanal:
        return fecha.add(Duration(days: 7));
      case ModalidadPago.quincenal:
        return fecha.add(Duration(days: 15));
      case ModalidadPago.mensual:
        return DateTime(fecha.year, fecha.month + 1, fecha.day);
      case ModalidadPago.personalizado:
        return fecha; // Se manejará manualmente
    }
  }
  
  // Validar que el margen de ganancia sea razonable
  static bool validarMargenGanancia(double inversion, double ganancia) {
    double porcentaje = (ganancia / inversion) * 100;
    return porcentaje >= 0 && porcentaje <= 1000; // Máximo 1000% de ganancia
  }
}