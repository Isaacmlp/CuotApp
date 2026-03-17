import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuot_app/Controller/credito_controller.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/widget/creditos/formulario_cuotas.dart';
import 'package:cuot_app/widget/creditos/formulario_pagounico.dart';
import 'package:cuot_app/widget/creditos/tipo_credito_selector.dart';
import 'package:cuot_app/ui/pages/seguimiento_creditos_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreditoPage extends StatelessWidget {
  final String nombreUsuario;

  const CreditoPage({super.key, required this.nombreUsuario});

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
        final credito = controller.creditoEnProceso!;
        File? facturaFile;
        if (credito.facturaPath != null) {
          facturaFile = File(credito.facturaPath!);
        }

        await controller.guardarCredito(
          credito, 
          nombreUsuario, 
          facturaArchivo: facturaFile,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crédito guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a SeguimientoCreditosPage
      
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SeguimientoCreditosPage(nombreUsuario: nombreUsuario),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Por favor, completa todos los campos primero'),
            backgroundColor: Colors.orange,
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