import 'package:flutter/material.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/Model/aporte_grupo_model.dart';
import 'package:cuot_app/Model/cuota_ahorro_model.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:cuot_app/utils/ahorro_logic_helper.dart';

class GrupoDashboardPage extends StatefulWidget {
  final String grupoId;
  final String usuarioNombre;

  const GrupoDashboardPage({
    super.key,
    required this.grupoId,
    required this.usuarioNombre,
  });

  @override
  State<GrupoDashboardPage> createState() => _GrupoDashboardPageState();
}

class _GrupoDashboardPageState extends State<GrupoDashboardPage> {
  final SavingsService _savingsService = SavingsService();
  GrupoAhorro? _grupo;
  List<MiembroGrupo> _miembros = [];
  bool _isLoading = true;
  
  // Caché de cuotas por miembro para evitar recargas constantes
  final Map<String, List<CuotaAhorro>> _cuotasCache = {};
  final Map<String, bool> _loadingCuotasCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grupo = await _savingsService.getGrupoById(widget.grupoId);
      final miembros = await _savingsService.getMiembros(widget.grupoId);

      setState(() {
        _grupo = grupo;
        _miembros = miembros;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando dashboard de grupo: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryGreen),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_grupo == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryGreen),
        body: const Center(child: Text('Error: No se pudo encontrar el grupo')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Realizar Sorteo',
                onPressed: _realizarSorteo,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar Grupo',
                onPressed: _confirmDeleteGrupo,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _grupo!.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        '\$${_grupo!.totalAcumulado.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Acumulado',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getProximoARecibir(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Miembros del Grupo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_miembros.length}/${_grupo!.cantidadParticipantes} Integrantes',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _miembros.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _miembros.length,
                          itemBuilder: (context, index) {
                            return _buildMiembroItem(_miembros[index]);
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Añadir Miembro'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Meta Grupal',
              '\$${_grupo!.metaAhorro.toStringAsFixed(0)}',
              Icons.flag_outlined,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(
              'Periodo',
              _grupo!.periodo.name.toUpperCase(),
              Icons.calendar_today_outlined,
            ),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildStatItem(
              'Tipo',
              _grupo!.tipoAporte == TipoAporte.comun ? 'FIJO' : 'VAR.',
              Icons.widgets_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No hay miembros registrados',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiembroItem(MiembroGrupo miembro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) {
              _loadCuotasMiembro(miembro.id!);
            }
          },
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
            child: Text(
              (miembro.nombreCliente ?? '?').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            miembro.nombreCliente ?? 'Cargando...',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      miembro.numeroTurno != null ? 'Turno ${miembro.numeroTurno}' : 'Sin Turno',
                      style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cuota: \$${miembro.montoCuota.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Aportado: \$${miembro.totalAportado.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            _buildCuotasList(miembro),
          ],
        ),
      ),
    );
  }

  Widget _buildCuotasList(MiembroGrupo miembro) {
    bool isLoading = _loadingCuotasCache[miembro.id] ?? false;
    List<CuotaAhorro>? cuotas = _cuotasCache[miembro.id];

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (cuotas == null || cuotas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No hay cuotas generadas', style: TextStyle(fontSize: 12, color: Colors.grey))),
      );
    }

    // Identificar el índice de la primera cuota NO pagada
    int primerIndicePendiente = cuotas.indexWhere((c) => !c.pagada);

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cuotas.length,
        itemBuilder: (context, index) {
          final c = cuotas[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: c.pagada ? AppColors.success.withOpacity(0.1) : Colors.grey.shade200,
              child: Text(
                c.numeroCuota.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: c.pagada ? AppColors.success : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Cuota #${c.numeroCuota}',
              style: TextStyle(
                fontWeight: c.pagada ? FontWeight.bold : FontWeight.normal,
                color: c.pagada ? AppColors.success : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Vence: ${DateUt.formatearFecha(c.fechaVencimiento)}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${c.montoEsperado.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (!c.pagada)
                  ElevatedButton(
                    onPressed: index == primerIndicePendiente
                        ? () => _showPayCuotaDialog(miembro, c)
                        : null, // BLOQUEADO si no es el turno
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 30),
                      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    child: Text(index == primerIndicePendiente ? 'PAGAR' : 'BLOQU.'),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _loadCuotasMiembro(String miembroId) async {
    if (_loadingCuotasCache[miembroId] == true) return;

    setState(() => _loadingCuotasCache[miembroId] = true);
    final cuotas = await _savingsService.getCuotasMiembro(miembroId);
    setState(() {
      _cuotasCache[miembroId] = cuotas;
      _loadingCuotasCache[miembroId] = false;
    });
  }

  void _showPayCuotaDialog(MiembroGrupo miembro, CuotaAhorro cuota) {
    showDialog(
      context: context,
      builder: (context) => DialogoPagoCuota(
        numeroCuota: cuota.numeroCuota,
        monto: cuota.pendiente,
        fechaVencimiento: cuota.fechaVencimiento,
        nombreCliente: miembro.nombreCliente ?? 'Miembro',
        onPagar: (monto, fecha, metodo, comprobante) async {
          final aporte = AporteGrupo(
            miembroId: miembro.id!,
            monto: monto,
            fechaAporte: fecha,
            metodoPago: metodo,
            observaciones: 'Pago Cuota #${cuota.numeroCuota}',
          );

          try {
            await _savingsService.saveAporte(aporte, cuotaId: cuota.id);
            if (mounted) {
              Navigator.pop(context);
              _loadData(); // Recargar balances globales
              _loadCuotasMiembro(miembro.id!); // Recargar lista de cuotas específica
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pago registrado correctamente'), backgroundColor: AppColors.success),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al registrar pago: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showAddMemberDialog() {
    if (_miembros.length >= _grupo!.cantidadParticipantes && _grupo!.cantidadParticipantes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya se ha alcanzado el límite de participantes para este grupo')),
      );
      return;
    }

    String query = '';
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;
    bool showCreateForm = false;

    // Calcular turnos disponibles
    final Set<int> usedTurns = _miembros
        .where((m) => m.numeroTurno != null)
        .map((m) => m.numeroTurno!)
        .toSet();
    
    List<int> availableTurns = [];
    if (_grupo!.cantidadParticipantes > 0) {
      for (int i = 1; i <= _grupo!.cantidadParticipantes; i++) {
        if (!usedTurns.contains(i)) availableTurns.add(i);
      }
    }
    
    int? selectedTurn;

    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController metaDialogController = TextEditingController(
      text: _grupo!.metaAhorro.toStringAsFixed(0),
    );
    final TextEditingController articuloController = TextEditingController();
    final TextEditingController cuotaController = TextEditingController(
      text: _grupo!.cantidadParticipantes > 0 ? (_grupo!.metaAhorro / _grupo!.cantidadParticipantes).toStringAsFixed(2) : '0',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Añadir Miembro'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!showCreateForm) ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar cliente...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) async {
                        if (val.length < 2) {
                          setDialogState(() {
                            results = [];
                            query = val;
                          });
                          return;
                        }
                        setDialogState(() => isSearching = true);
                        final res = await _savingsService.searchClientes(
                          val,
                          widget.usuarioNombre,
                        );
                        setDialogState(() {
                          results = res;
                          isSearching = false;
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isSearching)
                      const Center(child: CircularProgressIndicator())
                    else if (results.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (_, index) {
                          final c = results[index];
                          return ListTile(
                            title: Text(c['nombre']),
                            subtitle: Text(c['telefono'] ?? 'Sin telefono'),
                            trailing: const Icon(
                              Icons.person_add_alt_1,
                              color: AppColors.primaryGreen,
                            ),
                            onTap: () => _procederAnadir(
                              dialogContext,
                              c['id'].toString(),
                              c['nombre'],
                              metaDialogController,
                              articuloController,
                              cuotaController,
                              selectedTurn,
                            ),
                          );
                        },
                      )
                    else if (query.length >= 2)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'No se encontraron clientes',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cuotaController,
                      decoration: const InputDecoration(
                        labelText: 'Monto de Cuota',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: selectedTurn,
                      decoration: const InputDecoration(
                        labelText: 'Asignar Turno',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sortear después'),
                        ),
                        ...availableTurns.map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('Turno $t'),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedTurn = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: articuloController,
                      decoration: const InputDecoration(
                        labelText: '¿Qué comprará con el ahorro? (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: () =>
                          setDialogState(() => showCreateForm = true),
                      icon: const Icon(Icons.add),
                      label: const Text('CREAR NUEVO CLIENTE'),
                    ),
                  ] else ...[
                    const Text(
                      'Registrar y añadir nuevo cliente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: metaDialogController,
                      decoration: InputDecoration(
                        labelText: 'Meta',
                        prefixText: '\$ ',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cuotaController,
                      decoration: const InputDecoration(
                        labelText: 'Monto de Cuota',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: selectedTurn,
                      decoration: const InputDecoration(
                        labelText: 'Asignar Turno',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sortear después'),
                        ),
                        ...availableTurns.map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('Turno $t'),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedTurn = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: articuloController,
                      decoration: const InputDecoration(
                        labelText: '¿Qué comprará con el ahorro? (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setDialogState(() => showCreateForm = false),
                          child: const Text('Volver a buscar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                          onPressed: () async {
                            if (nameController.text.isEmpty) return;
                            try {
                              final id = await _savingsService.createCliente(
                                nameController.text,
                                phoneController.text,
                                widget.usuarioNombre,
                              );
                              _procederAnadir(
                                dialogContext,
                                id,
                                nameController.text,
                                metaDialogController,
                                articuloController,
                                cuotaController,
                                selectedTurn,
                              );
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al crear cliente: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Añadir'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _procederAnadir(
    BuildContext dialogContext,
    String clienteId,
    String nombreCliente,
    TextEditingController metaController,
    TextEditingController articuloController,
    TextEditingController cuotaController,
    int? selectedTurn,
  ) async {
    // Verificación estricta de cupo antes de proceder
    if (_miembros.length >= _grupo!.cantidadParticipantes) {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: El grupo ya alcanzó el límite de participantes'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    double metaPersonal = double.tryParse(metaController.text) ?? _grupo!.metaAhorro;
    double cuota = double.tryParse(cuotaController.text) ?? 0;
    String articulo = articuloController.text.trim();

    final miembro = MiembroGrupo(
      grupoId: widget.grupoId,
      clienteId: clienteId,
      montoMetaPersonal: metaPersonal,
      fechaIngreso: DateTime.now(),
      articuloDeseado: articulo.isNotEmpty ? articulo : null,
      numeroTurno: selectedTurn,
      montoCuota: cuota,
    );

    try {
      await _savingsService.addMiembro(miembro);
      // Cerrar el diálogo usando su propio context
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nombreCliente añadido al grupo'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir miembro: $e')),
        );
      }
    }
  }

  void _showAportesHistory(MiembroGrupo miembro) async {
    final aportes = await _savingsService.getAportes(miembro.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial: ${miembro.nombreCliente}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: aportes.isEmpty
                  ? const Center(child: Text('No hay aportes registrados'))
                  : ListView.builder(
                      itemCount: aportes.length,
                      itemBuilder: (context, index) {
                        final a = aportes[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.arrow_upward,
                            color: AppColors.success,
                          ),
                          title: Text('\$${a.monto.toStringAsFixed(2)}'),
                          subtitle: Text(DateUt.formatearFecha(a.fechaAporte)),
                          trailing: Text(
                            a.metodoPago.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGrupo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: const Text('¿Estás seguro de que deseas eliminar este grupo de ahorro? Esta acción no se puede deshacer y borrará todos los aportes de los miembros.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              try {
                await _savingsService.deleteGrupo(widget.grupoId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grupo eliminado exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context, true); // Regresar y recargar listado en SeguimientoCreditosPage
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar grupo: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _getProximoARecibir() {
    if (_grupo == null || _miembros.isEmpty) return 'Sin miembros';

    final info = AhorroLogicHelper.getTurnoInformacion(_grupo!, _miembros);

    if (info.turnoActual > _grupo!.cantidadParticipantes && _grupo!.cantidadParticipantes > 0) {
      return 'Turnos completados';
    }

    if (info.nombreProximo.contains('Turno')) {
      return 'Esperando Sorteo / ${info.nombreProximo}';
    }

    return 'Próximo a recibir: ${info.nombreProximo} (en ${info.diasRestantes} días)';
  }

    if (turnoActual > _grupo!.cantidadParticipantes && _grupo!.cantidadParticipantes > 0) {
      return 'Turnos completados';
    }

    // Buscar si hay alguien con ese turno
    final miembro = _miembros.where((m) => m.numeroTurno == turnoActual).firstOrNull;
    if (miembro != null) {
      return 'Próximo a recibir: ${miembro.nombreCliente} (Turno $turnoActual)';
    }

    return 'Esperando Sorteo / Turno $turnoActual libre';
  }

  Future<void> _realizarSorteo() async {
    final sinTurno = _miembros.where((m) => m.numeroTurno == null).toList();
    if (sinTurno.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los miembros ya tienen turno asignado')),
      );
      return;
    }

    final occupiedTurns = _miembros.where((m) => m.numeroTurno != null).map((m) => m.numeroTurno!).toSet();
    List<int> availableTurns = [];
    for (int i = 1; i <= _grupo!.cantidadParticipantes; i++) {
      if (!occupiedTurns.contains(i)) {
        availableTurns.add(i);
      }
    }

    if (availableTurns.length < sinTurno.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay suficientes turnos disponibles para sortear.')),
      );
      return;
    }

    availableTurns.shuffle();

    setState(() => _isLoading = true);
    for (int i = 0; i < sinTurno.length; i++) {
      final miembro = sinTurno[i];
      final turn = availableTurns[i];
      final actMiembro = MiembroGrupo(
        id: miembro.id,
        grupoId: miembro.grupoId,
        clienteId: miembro.clienteId,
        nombreCliente: miembro.nombreCliente,
        montoMetaPersonal: miembro.montoMetaPersonal,
        totalAportado: miembro.totalAportado,
        fechaIngreso: miembro.fechaIngreso,
        articuloDeseado: miembro.articuloDeseado,
        numeroTurno: turn,
        montoCuota: miembro.montoCuota,
      );
      await _savingsService.updateMiembro(actMiembro);
    }
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorteo realizado con éxito'), backgroundColor: AppColors.success),
      );
    }
  }
}

