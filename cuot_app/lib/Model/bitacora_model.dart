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
      case 'pago_cuota':
        return 'Pago de cuota';
      case 'pago_credito_unico':
        return 'Pago crédito único';
      case 'crear_credito':
        return 'Nuevo crédito';
      case 'editar_credito':
        return 'Crédito editado';
      case 'renovacion_credito':
        return 'Renovación de crédito';
      case 'compartir_credito':
        return 'Asignación de crédito';
      case 'crear_usuario':
        return 'Usuario creado';
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
