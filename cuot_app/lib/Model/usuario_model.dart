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
  final Map<String, dynamic>? configAsignacion; // 👈 NUEVO: JSONB de configuración

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
    this.configAsignacion,
  });

  // Alias para compatibilidad — muchos widgets usan `u.nombre`
  String get nombre => nombreCompleto;

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
      configAsignacion: json['config_asignacion'] != null 
          ? Map<String, dynamic>.from(json['config_asignacion']) 
          : null,
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
        'config_asignacion': configAsignacion,
      };

  Usuario copyWith({
    String? id,
    String? nombreCompleto,
    String? correoElectronico,
    String? telefono,
    String? cedula,
    String? rol,
    String? creadoPor,
    bool? activo,
    DateTime? fechaCreacion,
    String? cedulaUrl,
    Map<String, dynamic>? configAsignacion,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      telefono: telefono ?? this.telefono,
      cedula: cedula ?? this.cedula,
      rol: rol ?? this.rol,
      creadoPor: creadoPor ?? this.creadoPor,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      cedulaUrl: cedulaUrl ?? this.cedulaUrl,
      configAsignacion: configAsignacion ?? this.configAsignacion,
    );
  }
}
