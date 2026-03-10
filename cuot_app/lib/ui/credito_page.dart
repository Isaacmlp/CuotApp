// 🖥️ VISTA PRINCIPAL: Página de gestión de créditos
import 'package:cuot_app/Controller/credito_controller.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/widget/creditos/formulario_cuotas.dart';
import 'package:cuot_app/widget/creditos/formulario_pagounico.dart';
import 'package:cuot_app/widget/creditos/tipo_credito_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreditoPage extends StatelessWidget {
  const CreditoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreditoController(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gestión de Financiamientos'),
          centerTitle: true,
        ),
        body: Consumer<CreditoController>(
          builder: (context, controller, child) {
            // Si no hay tipo seleccionado, mostrar selector
            if (controller.tipoCreditoSeleccionado == null) {
              return TipoCreditoSelector(
                onTipoSeleccionado: controller.seleccionarTipoCredito,
              );
            }
            
            // Mostrar formulario según tipo
            return controller.tipoCreditoSeleccionado == TipoCredito.cuotas
                ? FormularioCuotas(
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                  )
                : FormularioPagounico(
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                  );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreditoPage()),
            );
          },
          tooltip: 'Nuevo crédito',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
  
  Future<void> _guardarCredito(
    BuildContext context,
    CreditoController controller,
  ) async {
    // Aquí se validaría y guardaría el crédito
    try {
      if (controller.creditoEnProceso != null) {
        await controller.guardarCredito(controller.creditoEnProceso!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crédito guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}