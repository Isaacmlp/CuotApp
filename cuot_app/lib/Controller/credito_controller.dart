// 🎮 LÓGICA DE NEGOCIO: Manejo de estado y operaciones
import 'package:cuot_app/Model/credito_model.dart';
import 'package:flutter/material.dart';

class CreditoController extends ChangeNotifier {
  TipoCredito? _tipoCreditoSeleccionado;
  Credito? _creditoEnProceso;
  final List<Credito> _creditos = [];

  // Getters
  TipoCredito? get tipoCreditoSeleccionado => _tipoCreditoSeleccionado;
  Credito? get creditoEnProceso => _creditoEnProceso;
  List<Credito> get creditos => List.unmodifiable(_creditos);
  
  // Métodos para manejar el flujo
  void seleccionarTipoCredito(TipoCredito tipo) {
    _tipoCreditoSeleccionado = tipo;
    _creditoEnProceso = null;
    notifyListeners();
  }
  
  void iniciarNuevoCredito() {
    _tipoCreditoSeleccionado = null;
    _creditoEnProceso = null;
    notifyListeners();
  }
  
  Future<void> guardarCredito(Credito credito) async {
    // Aquí iría la lógica para guardar en BD
    _creditos.add(credito);
    _creditoEnProceso = null;
    _tipoCreditoSeleccionado = null;
    notifyListeners();
  }
  
  void actualizarCreditoParcial(Credito credito) {
    _creditoEnProceso = credito;
    notifyListeners();
  }
  
  // Validaciones de negocio
  bool validarCredito(Credito credito) {
    if (credito.concepto.isEmpty) return false;
    if (credito.costeInversion <= 0) return false;
    if (credito.margenGanancia < 0) return false;
    if (credito.nombreCliente.isEmpty) return false;
    
    if (credito.cuotasPersonalizadas == TipoCredito.cuotas) {
      if (credito.numeroCuotas == null || credito.numeroCuotas! < 1) return false;
    }
    
    return true;
  }
}