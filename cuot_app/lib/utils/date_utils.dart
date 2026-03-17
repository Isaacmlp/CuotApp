/// Utilidades para manejo de fechas
class DateUt {
  
  /// Formatea una fecha a string dd/mm/yyyy
  static String formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
           '${fecha.month.toString().padLeft(2, '0')}/'
           '${fecha.year}';
  }

  /// Valida que las fechas estén en orden cronológico
  static bool fechasEnOrden(List<DateTime> fechas) {
    for (int i = 0; i < fechas.length - 1; i++) {
      if (fechas[i].isAfter(fechas[i + 1])) {
        return false;
      }
    }
    return true;
  }

  /// Calcula fechas sugeridas para cuotas diarias
  static List<DateTime> sugerirFechasDiarias(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: index + 1)),
    );
  }

  /// Calcula fechas sugeridas para cuotas semanales
  static List<DateTime> sugerirFechasSemanales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: (index + 1) * 7)),
    );
  }

  /// Calcula fechas sugeridas para cuotas quincenales
  static List<DateTime> sugerirFechasQuincenales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => fechaInicio.add(Duration(days: (index + 1) * 15)),
    );
  }

  /// Calcula fechas sugeridas para cuotas mensuales
  static List<DateTime> sugerirFechasMensuales(
    DateTime fechaInicio, 
    int cantidad
  ) {
    return List.generate(
      cantidad,
      (index) => DateTime(
        fechaInicio.year,
        fechaInicio.month + index + 1,
        fechaInicio.day,
      ),
    );
  }

  /// Calcula la diferencia en meses entre dos fechas para el resumen
  static int calcularDiferenciaMeses(DateTime inicio, DateTime fin) {
    if (fin.isBefore(inicio)) return 0;
    int meses = (fin.year - inicio.year) * 12 + (fin.month - inicio.month);
    return meses < 0 ? 0 : meses;
  }
}