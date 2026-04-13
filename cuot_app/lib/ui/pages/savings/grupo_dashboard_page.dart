import 'package:flutter/material.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/Model/aporte_grupo_model.dart';
import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/utils/date_utils.dart';

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
                      const SizedBox(height: 40),
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
                        '${_miembros.length} Integrantes',
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
      child: InkWell(
        onTap: () => _showAportesHistory(miembro),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    child: Text(
                      (miembro.nombreCliente ?? '?').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          miembro.nombreCliente ?? 'Cargando...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Aportado: \$${miembro.totalAportado.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(
                    Icons.add_card,
                    () => _showAddAporteDialog(miembro),
                    AppColors.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso: ${(miembro.progreso * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_grupo!.tipoAporte == TipoAporte.diferente)
                        Text(
                          'Meta: \$${miembro.montoMetaPersonal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: miembro.progreso,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  void _showAddAporteDialog(MiembroGrupo miembro) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aporte: ${miembro.nombreCliente}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Monto a aportar',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? monto = double.tryParse(amountController.text);
              if (monto == null || monto <= 0) return;

              final aporte = AporteGrupo(
                miembroId: miembro.id!,
                monto: monto,
                fechaAporte: DateTime.now(),
                observaciones: obsController.text,
              );

              try {
                await _savingsService.saveAporte(aporte);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aporte registrado correctamente'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    String query = '';
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;
    bool showCreateForm = false;

    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    // Campo meta siempre visible
    final TextEditingController metaDialogController = TextEditingController(
      text: _grupo!.metaAhorro.toStringAsFixed(0),
    );
    // Campo de articulo deseado
    final TextEditingController articuloController = TextEditingController();

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
                    if (_grupo!.tipoAporte == TipoAporte.diferente) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: metaDialogController,
                        decoration: InputDecoration(
                          labelText: 'Meta personal',
                          prefixText: '\$ ',
                          border: const OutlineInputBorder(),
                          helperText: 'Monto que debe aportar este miembro',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
  ) async {
    double metaPersonal = double.tryParse(metaController.text) ?? _grupo!.metaAhorro;
    String articulo = articuloController.text.trim();

    final miembro = MiembroGrupo(
      grupoId: widget.grupoId,
      clienteId: clienteId,
      montoMetaPersonal: metaPersonal,
      fechaIngreso: DateTime.now(),
      articuloDeseado: articulo.isNotEmpty ? articulo : null,
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
}
}