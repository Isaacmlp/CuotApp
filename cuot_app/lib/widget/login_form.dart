import 'package:flutter/material.dart';

class LoginForm {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  String obtenerCorreo() {
    return _correoController.text;
  }

  String obtenerContrasena() {
    return _contrasenaController.text;
  }

  TextEditingController getCorreo() {
    return _correoController;
  }

  TextEditingController getContrasena() {
    return _contrasenaController;
  }
}
