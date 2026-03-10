class Cliente {
  String id;
  String nombre;
  String? telefono;
  String? email;

  Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
  });
}