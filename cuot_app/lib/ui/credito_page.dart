import 'dart:io';
import 'package:cuot_app/Controller/credito_controller.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/widget/creditos/formulario_cuotas.dart';
import 'package:cuot_app/widget/creditos/formulario_pagounico.dart';
import 'package:cuot_app/widget/creditos/tipo_credito_selector.dart';
import 'package:cuot_app/ui/pages/detalle_credito_page.dart';

import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/creditos/formulario_grupo.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:provider/provider.dart';

class CreditoPage extends StatefulWidget {
  final String nombreUsuario;
  final String? creditoIdEditar;

  const CreditoPage({
    super.key,
    required this.nombreUsuario,
    this.creditoIdEditar,
  });

  @override
  State<CreditoPage> createState() => _CreditoPageState();
}

class _CreditoPageState extends State<CreditoPage> {
  final CreditoController _controller = CreditoController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.creditoIdEditar != null) {
      _cargarDatosEdicion();
    }
  }

  Future<void> _cargarDatosEdicion() async {
    setState(() => _isLoading = true);
    await _controller.cargarCreditoParaEdicion(widget.creditoIdEditar!);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.creditoIdEditar != null ? 'Editar Financiamiento' : 'Gestión de Cuotas'),
          centerTitle: true,
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Consumer<CreditoController>(
          builder: (context, controller, child) {
            // Si no hay tipo seleccionado, mostrar selector
            if (controller.tipoCreditoSeleccionado == null) {
              return TipoCreditoSelector(
                onTipoSeleccionado: controller.seleccionarTipoCredito,
              );
            }
            
            if (controller.tipoCreditoSeleccionado == TipoCredito.grupal) {
              return FormularioGrupo(
                nombreUsuario: widget.nombreUsuario,
                onGuardar: (grupo) => _guardarGrupo(context, grupo),
                isLoading: _isLoading,
              );
            }

            // Mostrar formulario según tipo
            return controller.tipoCreditoSeleccionado == TipoCredito.cuotas
                ? FormularioCuotas(
                    creditoInicial: controller.creditoEnProceso,
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                    isLoading: _isLoading, // 👈 PASAR ESTADO
                  )
                : FormularioPagounico(
                    creditoInicial: controller.creditoEnProceso,
                    totalPagado: controller.totalPagado,
                    onCreditoActualizado: controller.actualizarCreditoParcial,
                    onGuardar: () => _guardarCredito(context, controller),
                    isLoading: _isLoading, // 👈 PASAR ESTADO
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
    if (_isLoading) return; // BLOQUEO ANTI-DOBLE-CLICK

    setState(() => _isLoading = true);
    
    try {
      if (controller.creditoEnProceso != null) {
        final credito = controller.creditoEnProceso!;
        File? facturaFile;

        if (credito.facturaPath != null && !credito.facturaPath!.startsWith('http')) {
          facturaFile = File(credito.facturaPath!);
        }

        // Capturar referencias ANTES de cualquier operación async
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        bool creditoDuplicado = await controller.existeCreditoIdentico(credito, widget.nombreUsuario);
        if (creditoDuplicado) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text('Crédito duplicado')),
                  ],
                ),
                content: const Text('Ya existe un crédito exactamente igual (mismo cliente, concepto y monto).\n\nNo se permite guardar registros repetidos.'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ENTENDIDO'),
                  ),
                ],
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        bool existe = await controller.clienteExisteYEsDiferenteAlActual(credito.nombreCliente, widget.nombreUsuario);
        if (existe) {
          bool? continuar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(child: Text('Cliente registrado')),
                ],
              ),
              content: Text('Ya tienes un registro con el nombre "${credito.nombreCliente}".\n\n¿Deseas asignarle este nuevo crédito a ese mismo cliente?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('NO, CAMBIAR NOMBRE'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SÍ, ASIGNAR'),
                ),
              ],
            ),
          );
          if (continuar != true) {
            setState(() => _isLoading = false);
            return;
          }
        }

        debugPrint('🔵 Llamando controller.guardarCredito...');
        final String? creditId = await controller.guardarCredito(
          credito, 
          widget.nombreUsuario, 
          facturaArchivo: facturaFile,
        );
        debugPrint('🔵 guardarCredito retornó creditId: $creditId');

        // 🔑 NAVEGACIÓN INMEDIATA: No mostrar diálogo intermedio, navegar directo
        // Esto evita que un rebuild del Consumer desmonte el formulario
        if (creditId != null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Crédito guardado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          debugPrint('🟢 creditId no es nulo, navegando a DetalleCreditoPage...');
          // pushReplacement no depende de que esta página siga montada
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetalleCreditoPage(
                creditoId: creditId,
                nombreUsuario: widget.nombreUsuario,
              ),
            ),
          );
          debugPrint('🟢 pushReplacement ejecutado');
          return; // Salir sin ejecutar finally/setState
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('⚠️ Guardado, pero el ID retornó nulo. Regresando...'),
              backgroundColor: Colors.orange,
            ),
          );
          navigator.pop(true);
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Por favor, completa todos los campos primero'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarGrupo(BuildContext context, GrupoAhorro grupo) async {
    setState(() => _isLoading = true);
    try {
      final service = SavingsService();
      await service.createGrupo(grupo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Grupo de ahorro creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear grupo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}