import 'package:cuot_app/Model/usuario_model.dart';
import 'package:cuot_app/service/bitacora_service.dart';
import 'package:cuot_app/service/credit_service.dart';
import 'package:cuot_app/service/credito_compartido_service.dart';
import 'package:cuot_app/service/savings_service.dart'; // 👈 NUEVO
import 'package:cuot_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AssignmentMode { manual, todos, todosExcepto }

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

class _AsignarCreditoDialogState extends State<AsignarCreditoDialog> with SingleTickerProviderStateMixin {
  final CreditService _creditService = CreditService();
  final CreditoCompartidoService _compartidoService = CreditoCompartidoService();
  final SavingsService _savingsService = SavingsService(); // 👈 NUEVO
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _creditos = [];
  List<Map<String, dynamic>> _gruposAhorro = []; // 👈 NUEVO
  List<Map<String, dynamic>> _entidadesFiltradas = []; // 👈 Unificado
  
  Set<String> _selectedIds = {};
  Set<String> _initialIds = {}; 
  Map<String, String> _mapaAsignaciones = {}; 
  Map<String, String> _tipoEntidadPorId = {}; // 👈 id -> tipo (credito/grupo_ahorro)
  Set<String> _idsAsignadosYa = {};
  AssignmentMode _mode = AssignmentMode.manual;
  String _permisos = 'lectura';
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _submitProgress = 0;
  String? _error;

  // ── NUEVO: Control de pasos ──────────────────────────────────────────────
  String? _selectedCategory; // null = menú principal, 'simple', 'fija', 'grupo'
  List<String> _tiposPermitidos = []; // 👈 NUEVO: Filtro desde la DB

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    // MAPEO DE ROLES A PERMISOS COMPATIBLES CON LA DB
    if (widget.usuarioDestino.rol == 'supervisor') {
      _permisos = 'total';
    } else {
      _permisos = 'cobro'; // Default para empleados y otros
    }
    _cargarCreditos();
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
      _mode = AssignmentMode.values[_tabController.index];
      _updateSelectionByMode();
    });
  }

  void _updateSelectionByMode() {
    final allIds = {
      if (_tiposPermitidos.contains('simple')) 
        ..._creditos.where((c) => c['tipo_credito'] == 'unico').map((c) => c['id'].toString()),
      if (_tiposPermitidos.contains('fija')) 
        ..._creditos.where((c) => c['tipo_credito'] != 'unico').map((c) => c['id'].toString()),
      if (_tiposPermitidos.contains('grupo')) 
        ..._gruposAhorro.map((g) => g['id'].toString())
    };

    switch (_mode) {
      case AssignmentMode.manual:
        break;
      case AssignmentMode.todos:
        _selectedIds = allIds;
        break;
      case AssignmentMode.todosExcepto:
        _selectedIds = allIds;
        break;
    }
  }

  Future<void> _cargarCreditos() async {
    try {
      final rawCreditos = await _creditService.getFullCreditsData(widget.adminNombre);
      final rawGrupos = await _savingsService.getGrupos(widget.adminNombre);
      final asignados = await _compartidoService.obtenerCreditosAsignados(widget.usuarioDestino.nombreCompleto);
      
      final dynamic config = widget.usuarioDestino.configAsignacion?['tipos'];
      final List<String> prefs = (config is List) ? List<String>.from(config) : [];
      
      if (mounted) {
        setState(() {
          _tiposPermitidos = prefs.isEmpty ? ['simple', 'fija', 'grupo'] : prefs;
          _mapaAsignaciones = { for (var a in asignados) a.creditoId: a.id! };
          _initialIds = asignados.map((a) => a.creditoId).toSet();
          _selectedIds = Set.from(_initialIds);
          
          _creditos = rawCreditos.where((c) => c['estado'] != 'Fallido').toList();
          _gruposAhorro = rawGrupos.map((g) => g.toJson()).toList();

          // Mapear tipos
          _tipoEntidadPorId = {};
          for (var c in _creditos) _tipoEntidadPorId[c['id'].toString()] = 'credito';
          for (var g in _gruposAhorro) _tipoEntidadPorId[g['id'].toString()] = 'grupo_ahorro';

          _entidadesFiltradas = [..._creditos, ..._gruposAhorro];
          
          // Si solo hay un tipo permitido, seleccionarlo automáticamente
          if (_tiposPermitidos.length == 1) {
            _selectedCategory = _tiposPermitidos.first;
          }

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
      final q = query.toLowerCase();
      final all = [..._creditos, ..._gruposAhorro];
      
      if (q.isEmpty) {
        _entidadesFiltradas = all;
      } else {
        _entidadesFiltradas = all.where((e) {
          final nombre = (e['Clientes']?['nombre'] ?? e['nombre'] ?? '').toString().toLowerCase();
          final concepto = (e['concepto'] ?? '').toString().toLowerCase();
          final num = (e['numero_credito'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || concepto.contains(q) || num.contains(q);
        }).toList();
      }
    });
  }

  void _toggleSelection(String id) {
    
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmar() async {
    final toAssign = _selectedIds.difference(_initialIds);
    final toRevoke = _initialIds.difference(_selectedIds);

    if (toAssign.isEmpty && toRevoke.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitProgress = 0;
    });

    int count = 0;
    final total = toAssign.length + toRevoke.length;

    try {
      // 1. Procesar Asignaciones
      for (final id in toAssign) {
        final tipo = _tipoEntidadPorId[id] ?? 'credito';
        await _compartidoService.compartirCredito(
          creditoId: id,
          tipoEntidad: tipo,
          propietarioNombre: widget.adminNombre.trim(),
          trabajadorNombre: widget.usuarioDestino.nombreCompleto.trim(),
          permisos: _permisos,
        );

        String label = 'registro';
        if (tipo == 'grupo_ahorro') label = 'grupo de ahorro';

        await BitacoraService().registrarActividad(
          usuarioNombre: widget.adminNombre,
          accion: 'compartir_$tipo',
          descripcion: 'Asignó $label ID#$id a ${widget.usuarioDestino.nombreCompleto}',
          entidadTipo: tipo,
          entidadId: id,
        );

        count++;
        if (mounted) setState(() => _submitProgress = count / total);
      }

      // 2. Procesar Revocaciones
      for (final id in toRevoke) {
        final compartidoId = _mapaAsignaciones[id];
        if (compartidoId != null) {
          final tipo = _tipoEntidadPorId[id] ?? 'credito';
          await _compartidoService.revocarAcceso(compartidoId);

          await BitacoraService().registrarActividad(
            usuarioNombre: widget.adminNombre,
            accion: 'revocar_$tipo',
            descripcion: 'Revocó acceso a $tipo ID#$id a ${widget.usuarioDestino.nombreCompleto}',
            entidadTipo: tipo,
            entidadId: id,
          );
        }
        count++;
        if (mounted) setState(() => _submitProgress = count / total);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cambios aplicados correctamente ($total cambios)'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
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
      elevation: 12,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header Premium ──────────────────────────────────────────
              _buildHeader(),

              // ── Body ────────────────────────────────────────────────────
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCategory == null) ...[
                        const SizedBox(height: 30),
                        const Text(
                          '¿Qué deseas asignar?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                        ),
                        const SizedBox(height: 24),
                        _buildCategoryMenu(),
                        const SizedBox(height: 40),
                      ] else ...[
                        const SizedBox(height: 20),
                        _buildModeSelector(),
                        const SizedBox(height: 20),
                        
                        if (_mode != AssignmentMode.todos) ...[
                          _buildSearchBar(),
                          const SizedBox(height: 12),
                        ],
                        
                        _buildCreditList(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Footer ──────────────────────────────────────────────────
              if (_selectedCategory != null) _buildFooter(),
            ],
          ),
          
          if (_isSubmitting) _buildSubmitOverlay(),
        ],
      ),
    );
  }

  Widget _buildCategoryMenu() {
    return Column(
      children: [
        if (_tiposPermitidos.contains('simple'))
          _buildCategoryCard('Cuotas Simples', 'Cobros de un solo pago', Icons.flash_on, Colors.amber, 'simple'),
        if (_tiposPermitidos.contains('simple') && (_tiposPermitidos.contains('fija') || _tiposPermitidos.contains('grupo')))
          const SizedBox(height: 16),
        
        if (_tiposPermitidos.contains('fija'))
          _buildCategoryCard('Cuotas Fijas', 'Financiamientos recurrentes', Icons.calendar_month, Colors.blue, 'fija'),
        if (_tiposPermitidos.contains('fija') && _tiposPermitidos.contains('grupo'))
          const SizedBox(height: 16),

        if (_tiposPermitidos.contains('grupo'))
          _buildCategoryCard('Grupos de Ahorro', 'Susu / Ahorros grupales', Icons.groups, AppColors.primaryGreen, 'grupo'),
      ],
    );
  }

  Widget _buildCategoryCard(String title, String desc, IconData icon, Color color, String value) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          if (_selectedCategory != null && _tiposPermitidos.length > 1)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _selectedCategory = null),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: Text(
                widget.usuarioDestino.nombreCompleto.isNotEmpty ? widget.usuarioDestino.nombreCompleto[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Asignación',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Text(
                  widget.usuarioDestino.nombreCompleto,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Seleccionar'),
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
        hintText: 'Buscar cliente o concepto...',
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }

  Widget _buildCreditList() {
    if (_isLoading) {
      return const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }

    if (_mode == AssignmentMode.todos) {
      return _buildBulkStatus('Asignarás absolutamente todo al trabajador.');
    }
    
    if (_mode == AssignmentMode.todosExcepto) {
      return _buildBulkStatus('Se asignará todo, excepto lo que desmarques a continuación.');
    }

    // Clasificar entidades filtradas
    final simples = _entidadesFiltradas.where((e) => 
      _tipoEntidadPorId[e['id'].toString()] == 'credito' && 
      e['tipo_credito'] == 'unico'
    ).toList();

    final fijos = _entidadesFiltradas.where((e) => 
      _tipoEntidadPorId[e['id'].toString()] == 'credito' && 
      e['tipo_credito'] != 'unico'
    ).toList();

    final grupos = _entidadesFiltradas.where((e) => 
      _tipoEntidadPorId[e['id'].toString()] == 'grupo_ahorro'
    ).toList();

    return Expanded(
      child: ListView(
        shrinkWrap: false,
        children: [
          if (_selectedCategory == 'simple' && simples.isNotEmpty) ...[
            _buildSectionHeader('Cuotas Simples', Icons.flash_on, Colors.amber),
            ...simples.map((c) => _buildEntityItem(c, 'credito')),
            const SizedBox(height: 16),
          ],
          if (_selectedCategory == 'fija' && fijos.isNotEmpty) ...[
            _buildSectionHeader('Cuotas Fijas', Icons.calendar_month, Colors.blue),
            ...fijos.map((c) => _buildEntityItem(c, 'credito')),
            const SizedBox(height: 16),
          ],
          if (_selectedCategory == 'grupo' && grupos.isNotEmpty) ...[
            _buildSectionHeader('Grupos de Ahorro', Icons.groups, AppColors.primaryGreen),
            ...grupos.map((g) => _buildEntityItem(g, 'grupo_ahorro')),
          ],
          if (_entidadesFiltradas.isEmpty || 
              (_selectedCategory == 'simple' && simples.isEmpty) ||
              (_selectedCategory == 'fija' && fijos.isEmpty) ||
              (_selectedCategory == 'grupo' && grupos.isEmpty))
             const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay registros en esta categoría'))),
          const SizedBox(height: 80), // Espacio para el footer
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _buildEntityItem(Map<String, dynamic> item, String tipo) {
    final id = item['id'].toString();
    final bool isSelected = _selectedIds.contains(id);
    final bool yaAsignado = _initialIds.contains(id);
    
    String cliente = '';
    String subInfo = '';
    double monto = 0;

    if (tipo == 'credito') {
      cliente = item['Clientes']?['nombre'] ?? 'Cliente Desconocido';
      final num = item['numero_credito']?.toString() ?? '--';
      subInfo = 'Reg #$num • ${item['concepto'] ?? 'Sin concepto'}';
      monto = ((item['costo_inversion'] ?? 0) + (item['margen_ganancia'] ?? 0)).toDouble();
    } else {
      cliente = item['nombre'] ?? 'Grupo sin nombre';
      subInfo = 'Susu / Ahorro Grupal';
      monto = (item['monto_cuota'] ?? 0).toDouble();
    }

    return GestureDetector(
      onTap: () => _toggleSelection(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(id),
              activeColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cliente, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (yaAsignado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YA ASIGNADO',
                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    subInfo,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\$${monto.toStringAsFixed(0)}', 
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkStatus(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.done_all_rounded, size: 48, color: AppColors.primaryGreen),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Nivel de Acceso', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.darkGrey)),
        ),
        Row(
          children: [
            _buildPermisoItem('lectura', 'Lectura', Icons.visibility_outlined, AppColors.primaryGreen),
            const SizedBox(width: 8),
            _buildPermisoItem('cobro', 'Cobro', Icons.account_balance_wallet_outlined, Colors.orange),
            const SizedBox(width: 8),
            _buildPermisoItem('total', 'Total', Icons.security_outlined, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildPermisoItem(String value, String label, IconData icon, Color color) {
    final isSelected = _permisos == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _permisos = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final totalSelected = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
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
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                'Aplicar Cambios ($totalSelected)',
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
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Procesando asignaciones...', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _submitProgress, backgroundColor: Colors.grey.shade200, color: AppColors.primaryGreen),
              const SizedBox(height: 8),
              Text('${(_submitProgress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
