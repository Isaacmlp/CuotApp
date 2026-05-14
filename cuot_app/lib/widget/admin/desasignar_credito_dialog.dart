import 'package:cuot_app/Model/credito_compartido_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum DesasignarMode { quitarUno, quitarTodos, quitarTodosExcepto }

class DesasignarCreditoDialog extends StatefulWidget {
  final String adminNombre;
  final String empleadoNombre;
  final List<CreditoCompartido> asignaciones;
  final Map<String, Map<String, dynamic>> detallesCreditos;

  const DesasignarCreditoDialog({
    super.key,
    required this.adminNombre,
    required this.empleadoNombre,
    required this.asignaciones,
    required this.detallesCreditos,
  });

  @override
  State<DesasignarCreditoDialog> createState() => _DesasignarCreditoDialogState();
}

class _DesasignarCreditoDialogState extends State<DesasignarCreditoDialog> with SingleTickerProviderStateMixin {
  final CreditoCompartidoService _compartidoService = CreditoCompartidoService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<CreditoCompartido> _filtradas = [];
  Set<String> _selectedIds = {}; // IDs de la tabla Creditos_Compartidos
  DesasignarMode _mode = DesasignarMode.quitarUno;
  
  bool _isSubmitting = false;
  double _submitProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _filtradas = List.from(widget.asignaciones);
    _updateSelectionByMode();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _mode = DesasignarMode.values[_tabController.index];
      _updateSelectionByMode();
    });
  }

  void _updateSelectionByMode() {
    switch (_mode) {
      case DesasignarMode.quitarUno:
        _selectedIds.clear();
        break;
      case DesasignarMode.quitarTodos:
        _selectedIds = widget.asignaciones.map((a) => a.id!).toSet();
        break;
      case DesasignarMode.quitarTodosExcepto:
        _selectedIds = widget.asignaciones.map((a) => a.id!).toSet();
        break;
    }
  }

  void _filtrar(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtradas = List.from(widget.asignaciones);
      } else {
        final q = query.toLowerCase();
        _filtradas = widget.asignaciones.where((a) {
          final detalle = widget.detallesCreditos[a.creditoId];
          final cliente = (detalle?['Clientes']?['nombre'] ?? '').toString().toLowerCase();
          final num = (detalle?['numero_credito'] ?? '').toString().toLowerCase();
          return cliente.contains(q) || num.contains(q);
        }).toList();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_mode == DesasignarMode.quitarUno) {
        _selectedIds.clear();
        _selectedIds.add(id);
      } else {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      }
    });
  }

  Future<void> _confirmar() async {
    if (_selectedIds.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _submitProgress = 0;
    });

    int count = 0;
    final total = _selectedIds.length;

    try {
      for (final id in _selectedIds) {
        final asignacion = widget.asignaciones.firstWhere((a) => a.id == id);
        final detalle = widget.detallesCreditos[asignacion.creditoId];
        
        await _compartidoService.revocarAcceso(id);

        final String numCredito = detalle?['numero_credito']?.toString() ?? 'S/N';
        final String nombreCliente = detalle?['Clientes']?['nombre'] ?? 'Sin nombre';

        await BitacoraService().registrarActividad(
          usuarioNombre: widget.adminNombre,
          accion: 'revocar_credito',
          descripcion: 'Revocó acceso al registro #$numCredito ($nombreCliente) a ${widget.empleadoNombre}',
          entidadTipo: 'credito',
          entidadId: asignacion.creditoId,
        );

        count++;
        if (mounted) {
          setState(() {
            _submitProgress = count / total;
          });
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${total == 1 ? 'Acceso revocado' : '$total registros revocados'} correctamente',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      _buildModeSelector(),
                      const SizedBox(height: 20),
                      if (_mode != DesasignarMode.quitarTodos) ...[
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                      ],
                      _buildList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
          if (_isSubmitting) _buildSubmitOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.error, Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.delete_sweep, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revocar Registros',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  widget.empleadoNombre,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        labelColor: AppColors.error,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Quitar Uno'),
          Tab(text: 'Todos'),
          Tab(text: 'Todos Excepto'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filtrar,
      decoration: InputDecoration(
        hintText: 'Buscar registro...',
        prefixIcon: const Icon(Icons.search, color: AppColors.error),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildList() {
    if (_mode == DesasignarMode.quitarTodos) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Se revocarán los ${widget.asignaciones.length} registros asignados',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filtradas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final a = _filtradas[index];
          final detalle = widget.detallesCreditos[a.creditoId];
          final isSelected = _selectedIds.contains(a.id);
          
          return InkWell(
            onTap: () => _toggleSelection(a.id!),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.error.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.error : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(a.id!),
                    activeColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detalle?['Clientes']?['nombre'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Reg #${detalle?['numero_credito'] ?? '--'} • ${detalle?['concepto'] ?? ""}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    final totalSelected = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: totalSelected == 0 || _isSubmitting ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                totalSelected <= 1 ? 'Revocar Acceso' : 'Revocar $totalSelected Registros',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitOverlay() {
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.error),
              const SizedBox(height: 20),
              const Text('Revocando accesos...', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _submitProgress, backgroundColor: Colors.grey.shade200, color: AppColors.error),
              const SizedBox(height: 8),
              Text('${(_submitProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
