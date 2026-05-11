class CreditoCompartido {
  final String? id;
  final String creditoId;
  final String tipoEntidad; // 'credito' o 'grupo_ahorro'
  final String propietarioNombre;
  final String trabajadorNombre;
  final String permisos; // 'lectura', 'cobro', 'total'
  final bool activo;
  final DateTime? createdAt;

  CreditoCompartido({
    this.id,
    required this.creditoId,
    this.tipoEntidad = 'credito',
    required this.propietarioNombre,
    required this.trabajadorNombre,
    this.permisos = 'lectura',
    this.activo = true,
    this.createdAt,
  });

  // Helpers de permisos
  bool get puedeVer => true; // Todos los niveles pueden ver
  bool get puedeCobrar => permisos == 'cobro' || permisos == 'total';
  bool get puedeEditar => permisos == 'total';

  String get permisosDisplayName {
    switch (permisos) {
      case 'lectura':
        return 'Solo lectura';
      case 'cobro':
        return 'Lectura + Cobro';
      case 'total':
        return 'Control total';
      default:
        return permisos;
    }
  }

  String get tipoEntidadDisplayName {
    switch (tipoEntidad) {
      case 'credito':
        return 'Crédito';
      case 'grupo_ahorro':
        return 'Grupo de Ahorro';
      default:
        return tipoEntidad;
    }
  }

  factory CreditoCompartido.fromJson(Map<String, dynamic> json) {
    return CreditoCompartido(
      id: json['id']?.toString(),
      creditoId: json['credito_id']?.toString() ?? '',
      tipoEntidad: json['tipo_entidad'] ?? 'credito',
      propietarioNombre: json['propietario_nombre'] ?? '',
      trabajadorNombre: json['trabajador_nombre'] ?? '',
      permisos: json['permisos'] ?? 'lectura',
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'credito_id': creditoId,
        'tipo_entidad': tipoEntidad,
        'propietario_nombre': propietarioNombre,
        'trabajador_nombre': trabajadorNombre,
        'permisos': permisos,
        'activo': activo,
      };
}
