import 'package:cuot_app/utils/formatters.dart';

class Validators {
  // 🔧 LÓGICA: Validar campo requerido
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar teléfono (10 dígitos)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'El teléfono debe tener 10 dígitos';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar cédula (entre 7 y 10 dígitos)
  static String? cedula(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 10) {
      return 'La cédula debe tener entre 7 y 10 dígitos';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar contraseña
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    
    // Opcional: Validar fortaleza
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    
    return null;
  }

  // 🔧 LÓGICA: Validar que dos contraseñas coincidan
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return null;
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar número positivo
  static String? positiveNumber(String? value, String s, {bool allowZero = false}) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingrese un número válido';
    }
    
    if (allowZero) {
      if (number < 0) return 'El número debe ser mayor o igual a 0';
    } else {
      if (number <= 0) return 'El número debe ser mayor a 0';
    }
    
    return null;
  }

  // 🔧 LÓGICA: Validar entero
  static String? integer(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) return null;
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Ingrese un número entero válido';
    }
    
    if (min != null && number < min) {
      return 'El número debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max) {
      return 'El número debe ser menor o igual a $max';
    }
    
    return null;
  }

  // 🔧 LÓGICA: Validar decimal
  static String? decimal(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Ingrese un número decimal válido';
    }
    
    if (min != null && number < min) {
      return 'El número debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max) {
      return 'El número debe ser menor o igual a $max';
    }
    
    return null;
  }

  // 🔧 LÓGICA: Validar longitud mínima
  static String? minLength(String? value, int length, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < length) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $length caracteres';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar longitud máxima
  static String? maxLength(String? value, int length, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > length) {
      return '${fieldName ?? 'Este campo'} debe tener máximo $length caracteres';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Ingrese una URL válida';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar rango de fechas
  static String? dateRange(DateTime? date, {DateTime? min, DateTime? max}) {
    if (date == null) return null;
    
    if (min != null && date.isBefore(min)) {
      return 'La fecha debe ser posterior a ${Formatters.formatDate(min)}';
    }
    
    if (max != null && date.isAfter(max)) {
      return 'La fecha debe ser anterior a ${Formatters.formatDate(max)}';
    }
    
    return null;
  }

  // 🔧 LÓGICA: Validar que la fecha no sea futura
  static String? notFutureDate(DateTime? date) {
    if (date == null) return null;
    
    if (date.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar que la fecha no sea pasada
  static String? notPastDate(DateTime? date) {
    if (date == null) return null;
    
    if (date.isBefore(DateTime.now())) {
      return 'La fecha no puede ser pasada';
    }
    return null;
  }

  // 🔧 LÓGICA: Validar RUT (para Chile)
  static String? rut(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Eliminar puntos y guión
    final clean = value.replaceAll(RegExp(r'[\.\-]'), '');
    
    if (clean.length < 8 || clean.length > 9) {
      return 'RUT inválido';
    }
    
    final body = clean.substring(0, clean.length - 1);
    final dv = clean.substring(clean.length - 1).toUpperCase();
    
    // Calcular dígito verificador
    int sum = 0;
    int multiplier = 2;
    
    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }
    
    final remainder = sum % 11;
    final calculatedDV = remainder == 0 ? '0' : (11 - remainder == 10 ? 'K' : (11 - remainder).toString());
    
    if (dv != calculatedDV) {
      return 'RUT inválido';
    }
    
    return null;
  }


  
  static String? numeric(String? value, {String fieldName = 'Valor'}) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    if (number < 0) {
      return '$fieldName no puede ser negativo';
    }
    return null;
  }
  

}