import 'dart:io';
import 'package:cuot_app/Controller/credito_controller.dart';
import 'package:cuot_app/Model/credito_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/widget/creditos/formulario_cuotas.dart';
import 'package:cuot_app/widget/creditos/formulario_pagounico.dart';
import 'package:cuot_app/widget/creditos/tipo_credito_selector.dart';
import 'package:cuot_app/ui/pages/detalle_credito_page.dart';

import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/widget/creditos/formulario_grupo.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/ui/pages/savings/grupo_dashboard_page.dart';
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
          bottom: _isLoading ? const PreferredSize(
            preferredSize: Size.fromHeight(4),
            child: LinearProgressIndicator(backgroundColor: Colors.transparent),
          ) : null,
        ),
        body: Stack(
          children: [
            Consumer<CreditoController>(
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
                        isLoading: _isLoading,
                      )
                    : FormularioPagounico(
                        creditoInicial: controller.creditoEnProceso,
                        totalPagado: controller.totalPagado,
                        onCreditoActualizado: controller.actualizarCreditoParcial,
                        onGuardar: () => _guardarCredito(context, controller),
                        isLoading: _isLoading,
                      );
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Procesando...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarCredito(
    BuildContext context,
    CreditoController controller,
  ) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (controller.creditoEnProceso != null) {
        final credito = controller.creditoEnProceso!;
        File? facturaFile;

        if (credito.facturaPath != null && !credito.facturaPath!.startsWith('http')) {
          facturaFile = File(credito.facturaPath!);
        }

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

        if (creditId != null) {
          // Registrar en bitácora
          await BitacoraService().registrarActividad(
            usuarioNombre: widget.nombreUsuario,
            accion: widget.creditoIdEditar != null ? 'editar_credito' : 'crear_credito',
            descripcion: '${widget.creditoIdEditar != null ? 'Editó' : 'Creó'} crédito para ${credito.nombreCliente}',
            entidadTipo: 'credito',
            entidadId: creditId,
          );

          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Crédito guardado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetalleCreditoPage(
                creditoId: creditId,
                nombreUsuario: widget.nombreUsuario,
              ),
            ),
          );
          return;
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se pudo confirmar el guardado. Revisa los datos e intenta de nuevo.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Se mantiene en la pantalla para no perder los datos
          return;
        }
      } else {
        scaffoldMessenger.showSnackBar(
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
      final nuevoGrupo = await service.createGrupo(grupo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo de ahorro creado exitosamente'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GrupoDashboardPage(
              grupoId: nuevoGrupo.id!,
              usuarioNombre: widget.nombreUsuario,
              autoOpenAddMember: true, // REQUERIMIENTO 4
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear grupo: $e'),
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