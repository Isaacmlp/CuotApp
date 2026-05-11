import 'package:flutter/material.dart';

class AppConstants {
  // 🔧 LÓGICA: Configuración de la app
  static const String appName = 'Mi App de Créditos';
  static const String appVersion = '1.0.0';
  
  // 🔧 LÓGICA: URLs y endpoints
  static const String supabaseUrl = 'https://xtywfbdxtrloqvoxcbjb.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key'; // ⚠️ En producción usar .env
  
  // 🔧 LÓGICA: Buckets de Storage
  static const String facturasBucket = 'facturas';
  static const String documentosBucket = 'documentos';
  static const String capturasBucket = 'Capture';
  
  // 🔧 LÓGICA: Tablas de Supabase
  static const String tableUsuarios = 'Usuarios';
  static const String tableCredenciales = 'Credenciales';
  static const String tableCreditos = 'creditos';
  static const String tableClientes = 'clientes';
  static const String tableProductos = 'productos';
  static const String tablePagos = 'pagos';
  
  // 🔧 LÓGICA: Estados de crédito
  static const Map<String, String> estadosCredito = {
    'activo': 'Activo',
    'pagado': 'Pagado',
    'vencido': 'Vencido',
    'castigado': 'Castigado',
  };
  
  static const List<String> estadosCreditoList = [
    'activo',
    'pagado',
    'vencido',
    'castigado',
  ];
  
  // 🔧 LÓGICA: Formas de pago
  static const Map<String, String> formasPago = {
    'semanal': 'Semanal',
    'quincenal': 'Quincenal',
    'mensual': 'Mensual',
  };
  
  static const List<String> formasPagoList = [
    'semanal',
    'quincenal',
    'mensual',
  ];
  
  // 🔧 LÓGICA: Días según forma de pago
  static const Map<String, int> diasPorFormaPago = {
    'semanal': 7,
    'quincenal': 15,
    'mensual': 30,
  };
  
  // 🔧 LÓGICA: Rutas de navegación
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeCreditos = '/creditos';
  static const String routeNuevoCredito = '/creditos/nuevo';
  static const String routeDetalleCredito = '/creditos/detalle';
  static const String routeClientes = '/clientes';
  static const String routeReportes = '/reportes';
  
  // 🔧 LÓGICA: Preferencias compartidas
  static const String prefUserData = 'user_data';
  static const String prefSessionToken = 'session_token';
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotifications = 'notifications_enabled';
  
  // 🔧 LÓGICA: Mensajes de la app
  static const String msgErrorGenerico = 'Ha ocurrido un error. Intente nuevamente.';
  static const String msgSinInternet = 'Sin conexión a internet';
  static const String msgSesionExpirada = 'Sesión expirada. Inicie sesión nuevamente.';
  static const String msgGuardadoExitoso = 'Datos guardados exitosamente';
  static const String msgEliminarConfirmacion = '¿Está seguro que desea eliminar?';
  
  // 🔧 LÓGICA: Configuración de paginación
  static const int itemsPorPagina = 20;
  static const int productosPorPagina = 10;
  
  // 🔧 LÓGICA: Límites de la app
  static const int maxCuotasCredito = 36;
  static const int minCuotasCredito = 1;
  static const double maxInteresCredito = 50.0;
  static const double minInteresCredito = 0.0;
  static const int maxProductosPorCredito = 50;
  
  // 🔧 LÓGICA: Formatos de fecha
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateFormatDatabase = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  static const String dateTimeFormatDatabase = 'yyyy-MM-dd HH:mm:ss';
  
  // 🔧 LÓGICA: Colores de la app
  static const Color primaryColor = Color(0xFF2E7D32); // Verde oscuro
  static const Color secondaryColor = Color(0xFF1565C0); // Azul
  static const Color accentColor = Color(0xFFFF8F00); // Ámbar
  static const Color successColor = Color(0xFF2E7D32); // Verde
  static const Color errorColor = Color(0xFFC62828); // Rojo
  static const Color warningColor = Color(0xFFFF6F00); // Naranja
  static const Color infoColor = Color(0xFF1565C0); // Azul
  
  // 🔧 LÓGICA: Animaciones
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // 🔧 LÓGICA: Tamaños
  static const double borderRadiusSmall = 4;
  static const double borderRadiusMedium = 8;
  static const double borderRadiusLarge = 12;
  static const double borderRadiusXLarge = 16;
  
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;
  
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeXLarge = 48;
  
  // 🔧 LÓGICA: Categorías de productos predefinidas
  static const List<String> categoriasProducto = [
    'Electrónica',
    'Línea Blanca',
    'Muebles',
    'Ropa',
    'Calzado',
    'Hogar',
    'Herramientas',
    'Juguetes',
    'Deportes',
    'Otros',
  ];
  
  // 🔧 LÓGICA: Tipos de documento
  static const Map<String, String> tiposDocumento = {
    'cc': 'Cédula de Ciudadanía',
    'ce': 'Cédula de Extranjería',
    'nit': 'NIT',
    'pasaporte': 'Pasaporte',
  };
  
  // 🔧 LÓGICA: Obtener texto de estado
  static String getEstadoText(String estado) {
    return estadosCredito[estado] ?? estado;
  }
  
  // 🔧 LÓGICA: Obtener color de estado
  static Color getEstadoColor(String estado) {
    switch (estado) {
      case 'activo':
        return successColor;
      case 'pagado':
        return infoColor;
      case 'vencido':
        return errorColor;
      case 'castigado':
        return warningColor;
      default:
        return Colors.grey;
    }
  }
  
  // 🔧 LÓGICA: Obtener icono de estado
  static IconData getEstadoIcon(String estado) {
    switch (estado) {
      case 'activo':
        return Icons.check_circle;
      case 'pagado':
        return Icons.verified;
      case 'vencido':
        return Icons.warning;
      case 'castigado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  
  // 🔧 LÓGICA: Validar si un valor está dentro de los límites
  static bool isValidCuotas(int cuotas) {
    return cuotas >= minCuotasCredito && cuotas <= maxCuotasCredito;
  }
  
  static bool isValidInteres(double interes) {
    return interes >= minInteresCredito && interes <= maxInteresCredito;
  }
}

// 🔧 LÓGICA: Clase separada para mensajes de error específicos
class ErrorMessages {
  static const String networkError = 'Error de conexión. Verifique su internet.';
  static const String serverError = 'Error en el servidor. Intente más tarde.';
  static const String authError = 'Error de autenticación.';
  static const String notFoundError = 'Recurso no encontrado.';
  static const String validationError = 'Error de validación.';
  static const String permissionError = 'No tiene permisos para esta acción.';
  static const String timeoutError = 'Tiempo de espera agotado.';
  static const String unknownError = 'Error desconocido.';
}

// 🔧 LÓGICA: Clase separada para rutas de assets
class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String animations = 'assets/animations/';
  
  static const String logo = '${images}logo.png';
  static const String placeholder = '${images}placeholder.jpg';
  static const String emptyState = '${images}empty_state.png';
  static const String errorState = '${images}error_state.png';
}