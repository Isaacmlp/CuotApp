class ProductoModel {
  final int? id;
  final String nombre;
  final String? descripcion;
  final double precioUnitario;
  final int? cantidad;
  final String? categoria;

  ProductoModel({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.precioUnitario,
    this.cantidad,
    this.categoria,
  });

  // 🔧 LÓGICA: Convertir de JSON a objeto
  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      precioUnitario: (json['precio_unitario'] ?? 0).toDouble(),
      cantidad: json['cantidad'],
      categoria: json['categoria'],
    );
  }

  // 🔧 LÓGICA: Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
      'categoria': categoria,
    };
  }
}