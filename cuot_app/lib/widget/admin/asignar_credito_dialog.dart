import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AsignarCreditoDialog extends StatefulWidget {
  final String adminNombre;
  final Usuario usuarioDestino;

  const AsignarCreditoDialog({
    super.key,
    required this.adminNombre,
    required this.usuarioDestino,
  });

  @override
  State<AsignarCreditoDialog> createState() => _AsignarCreditoDialogState();
}

class _AsignarCreditoDialogState extends State<AsignarCreditoDialog> {
  final CreditService _creditService = CreditService();
  final CreditoCompartidoService _compartidoService = CreditoCompartidoService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _creditos = [];
  List<Map<String, dynamic>> _creditosFiltrados = [];
  Map<String, dynamic>? _creditoSeleccionado;
  String _permisos = 'lectura';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCreditos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarCreditos() async {
    try {
      // 1. Cargar créditos del administrador
      final raw = await _creditService.getFullCreditsData(widget.adminNombre);
      
      // 2. Cargar créditos que YA tiene asignados el usuario destino
      final asignados = await _compartidoService.obtenerCreditosAsignados(widget.usuarioDestino.nombreCompleto);
      final setIdsAsignados = asignados.map((a) => a.creditoId).toSet();

      if (mounted) {
        setState(() {
          // Filtrar: No fallidos Y que no estén ya asignados a este usuario específico
          _creditos = raw.where((c) {
            final bool noFallido = c['estado'] != 'Fallido';
            final bool noAsignadoYa = !setIdsAsignados.contains(c['id'].toString());
            return noFallido && noAsignadoYa;
          }).toList();
          
          _creditosFiltrados = List.from(_creditos);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar créditos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        _creditosFiltrados = List.from(_creditos);
      } else {
        final q = query.toLowerCase();
        _creditosFiltrados = _creditos.where((c) {
          final cliente = (c['Clientes']?['nombre'] ?? '').toString().toLowerCase();
          final concepto = (c['concepto'] ?? '').toString().toLowerCase();
          return cliente.contains(q) || concepto.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _confirmar() async {
    if (_creditoSeleccionado == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _compartidoService.compartirCredito(
        creditoId: _creditoSeleccionado!['id'].toString(),
        propietarioNombre: widget.adminNombre.trim(),
        trabajadorNombre: widget.usuarioDestino.nombreCompleto.trim(),
        permisos: _permisos,
      );

      if (mounted) {
        // Registrar en bitácora con información descriptiva (Número de crédito y Cliente)
        final String numCredito = _creditoSeleccionado!['numero_credito']?.toString() ?? 'S/N';
        final String nombreCliente = _creditoSeleccionado!['Clientes']?['nombre'] ?? 'Sin nombre';

        await BitacoraService().registrarActividad(
          usuarioNombre: widget.adminNombre,
          accion: 'compartir_credito',
          descripcion: 'Asignó crédito #$numCredito ($nombreCliente) a ${widget.usuarioDestino.nombreCompleto}',
          entidadTipo: 'credito',
          entidadId: _creditoSeleccionado!['id'].toString(),
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Crédito asignado a ${widget.usuarioDestino.nombreCompleto}',
              ),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    widget.usuarioDestino.nombreCompleto.isNotEmpty
                        ? widget.usuarioDestino.nombreCompleto[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignar Crédito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.usuarioDestino.nombreCompleto,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Búsqueda
                  TextField(
                    controller: _searchController,
                    onChanged: _filtrar,
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente o concepto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filtrar('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista de créditos
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                    )
                  else if (_creditosFiltrados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No hay créditos disponibles para asignar'),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.32,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _creditosFiltrados.length,
                        itemBuilder: (context, index) {
                          final c = _creditosFiltrados[index];
                          final cliente = c['Clientes']?['nombre'] ?? 'Sin nombre';
                          final concepto = c['concepto'] ?? '';
                          final monto = ((c['costo_inversion'] ?? 0) +
                              (c['margen_ganancia'] ?? 0)).toDouble();
                          final isSelected = _creditoSeleccionado?['id'] == c['id'];

                          return GestureDetector(
                            onTap: () => setState(() => _creditoSeleccionado = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryGreen.withOpacity(0.08)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.credit_card,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cliente,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isSelected
                                                ? AppColors.primaryGreen
                                                : AppColors.darkGrey,
                                          ),
                                        ),
                                        if (concepto.isNotEmpty)
                                          Text(
                                            concepto,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${monto.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : AppColors.darkGrey,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.check_circle,
                                          color: AppColors.primaryGreen, size: 18),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Selector de permisos
                  const Text(
                    'Nivel de Permisos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPermisoChip('lectura', 'Solo Ver', Icons.visibility_outlined),
                      _buildPermisoChip('cobro', 'Ver + Cobrar', Icons.payment_outlined),
                      _buildPermisoChip('total', 'Control Total', Icons.admin_panel_settings_outlined),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_creditoSeleccionado == null || _isSubmitting)
                        ? null
                        : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Asignar Crédito',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisoChip(String value, String label, IconData icon) {
    final isSelected = _permisos == value;

    Color color;
    switch (value) {
      case 'cobro':
        color = Colors.orange;
        break;
      case 'total':
        color = Colors.blue;
        break;
      default:
        color = AppColors.primaryGreen;
    }

    return GestureDetector(
      onTap: () => setState(() => _permisos = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
