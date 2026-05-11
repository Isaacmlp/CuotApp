class BitacoraActividad {
  final String? id;
  final String usuarioNombre;
  final String accion;
  final String? descripcion;
  final String? entidadTipo;
  final String? entidadId;
  final DateTime? createdAt;

  BitacoraActividad({
    this.id,
    required this.usuarioNombre,
    required this.accion,
    this.descripcion,
    this.entidadTipo,
    this.entidadId,
    this.createdAt,
  });

  String get accionDisplayName {
    switch (accion) {
      case 'login':
        return 'Inicio de sesión';
      case 'logout':
        return 'Cierre de sesión';
      case 'crear_usuario':
        return 'Creación de usuario';
      case 'editar_rol':
        return 'Edición de rol';
      case 'toggle_activo':
        return 'Cambio de estado';
      case 'reset_contrasena':
        return 'Reseteo de contraseña';
      case 'agregar_pago':
        return 'Pago registrado';
      case 'editar_credito':
        return 'Crédito editado';
      case 'eliminar_credito':
        return 'Crédito eliminado';
      case 'compartir_credito':
        return 'Crédito compartido';
      default:
        return accion;
    }
  }

  factory BitacoraActividad.fromJson(Map<String, dynamic> json) {
    return BitacoraActividad(
      id: json['id']?.toString(),
      usuarioNombre: json['usuario_nombre'] ?? '',
      accion: json['accion'] ?? '',
      descripcion: json['descripcion'],
      entidadTipo: json['entidad_tipo'],
      entidadId: json['entidad_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_nombre': usuarioNombre,
        'accion': accion,
        'descripcion': descripcion,
        'entidad_tipo': entidadTipo,
        'entidad_id': entidadId,
      };
}
