class Usuario {
  final String? id;
  final String nombreCompleto;
  final String correoElectronico;
  final String? telefono;
  final String? cedula;
  final String rol;
  final String? creadoPor;
  final bool activo;
  final DateTime? fechaCreacion;
  final String? cedulaUrl;

  Usuario({
    this.id,
    required this.nombreCompleto,
    required this.correoElectronico,
    this.telefono,
    this.cedula,
    this.rol = 'cliente',
    this.creadoPor,
    this.activo = true,
    this.fechaCreacion,
    this.cedulaUrl,
  });

  // Helpers de rol
  bool get isAdmin => rol == 'admin';
  bool get isSupervisor => rol == 'supervisor';
  bool get isEmpleado => rol == 'empleado';
  bool get isCliente => rol == 'cliente';
  bool get isTrabajador => isSupervisor || isEmpleado;

  String get rolDisplayName {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'supervisor':
        return 'Supervisor';
      case 'empleado':
        return 'Empleado';
      case 'cliente':
        return 'Cliente';
      default:
        return 'Usuario';
    }
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString(),
      nombreCompleto: (json['Nombre_Completo'] ?? '').toString(),
      correoElectronico: (json['Correo_Electronico'] ?? '').toString(),
      telefono: json['Telefono']?.toString(),
      cedula: json['Cedula']?.toString(),
      rol: (json['rol'] ?? 'cliente').toString(),
      creadoPor: json['creado_por']?.toString(),
      activo: json['activo'] ?? true,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      cedulaUrl: json['cedula_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Nombre_Completo': nombreCompleto,
        'Correo_Electronico': correoElectronico,
        'Telefono': telefono,
        'Cedula': cedula,
        'rol': rol,
        'creado_por': creadoPor,
        'activo': activo,
        'cedula_url': cedulaUrl,
      };
}
