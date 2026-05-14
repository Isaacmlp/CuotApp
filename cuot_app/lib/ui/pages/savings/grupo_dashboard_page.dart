import 'package:cuot_app/service/savings_service.dart';
import 'package:cuot_app/service/whatsapp_service.dart';
import 'package:flutter/material.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';
import 'package:cuot_app/Model/miembro_grupo_model.dart';
import 'package:cuot_app/Model/aporte_grupo_model.dart';
import 'package:cuot_app/Model/cuota_ahorro_model.dart';
import 'package:cuot_app/widget/seguimiento/dialogo_pago_cuota.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/utils/date_utils.dart';
import 'package:cuot_app/utils/ahorro_logic_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cuot_app/widget/creditos/formulario_grupo.dart';

class GrupoDashboardPage extends StatefulWidget {
  final String grupoId;
  final String usuarioNombre;
  final bool autoOpenAddMember; // Requerimiento 4

  const GrupoDashboardPage({
    super.key,
    required this.grupoId,
    required this.usuarioNombre,
    this.autoOpenAddMember = false,
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

  // Estadísticas del turno actual
  double _porCobrarTurno = 0;
  double _canceladoTurno = 0;
  double _totalRecaudacionTurno = 0;
  double _promedioTurno = 0;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) {
      if (widget.autoOpenAddMember) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddMemberDialog();
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grupo = await _savingsService.getGrupoById(widget.grupoId);
      final miembros = await _savingsService.getMiembros(widget.grupoId);

      // Ordenar miembros por turno (menor a mayor, null al final)
      miembros.sort((a, b) => (a.numeroTurno ?? 999).compareTo(b.numeroTurno ?? 999));

      double pc = 0, can = 0, tot = 0, prom = 0;
      if (grupo != null && grupo.turnoActual > 0) {
        final stats = await _savingsService.getStatsTurno(grupo.id!, grupo.turnoActual);
        pc = stats['porCobrar'] ?? 0;
        can = stats['cancelado'] ?? 0;
        tot = stats['total'] ?? 0;
        double pendCount = stats['pendientesCount'] ?? 0;
        
        if (pendCount > 0) {
          prom = pc / pendCount;
        }
      }

      setState(() {
        _grupo = grupo;
        _miembros = miembros;
        _porCobrarTurno = pc;
        _canceladoTurno = can;
        _totalRecaudacionTurno = tot;
        _promedioTurno = prom;
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
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar Grupo',
                onPressed: _tienePagos ? null : _showEditGrupoDialog,
                color: _tienePagos ? Colors.white54 : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar Grupo',
                onPressed: _confirmDeleteGrupo,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
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
                        'Recaudado', // TERMINOLOGÍA ACTUALIZADA
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
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHeaderStat('Por cobrar', '\$${_porCobrarTurno.toStringAsFixed(0)}'),
                            _buildHeaderStat('Cancelado', '\$${_canceladoTurno.toStringAsFixed(0)}'),
                            _buildHeaderStat('Promedio', '\$${_promedioTurno.toStringAsFixed(0)}'),
                          ],
                        ),
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
                  if (_grupo!.fechaPrimerPago == null) ...[
                    const SizedBox(height: 16),
                    _buildIniciarSusuBanner(),
                  ],
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
      floatingActionButton: _tienePagos ? null : FloatingActionButton(
        onPressed: _showAddMemberDialog,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsRow() {
    // Buscar quién tiene este turno (para mostrar quién recibe)
    String nombreRecibe = (_miembros.isEmpty) ? '...' : 'Sin asignar';
    if (_miembros.isNotEmpty) {
      final m = _miembros.where((m) => m.numeroTurno == _grupo!.turnoActual).firstOrNull;
      if (m != null) nombreRecibe = m.nombreCliente ?? 'N/A';
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Asignar (Sorteo) - MOVIDO AQUÍ
                InkWell(
                  onTap: () => _realizarSorteo(),
                  borderRadius: BorderRadius.circular(8),
                  child: _buildStatItem(
                    'Sorteo',
                    'Asignar',
                    FontAwesomeIcons.dice,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                
                // 2. Entregar Turno - MOVIDO AQUÍ
                InkWell(
                  onTap: _grupo!.fechaPrimerPago != null ? () => _showEntregarTurnoConfirm() : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Opacity(
                    opacity: _grupo!.fechaPrimerPago != null ? 1.0 : 0.5,
                    child: _buildStatItem(
                      'Entregar',
                      'Turno #${_grupo!.turnoActual}',
                      Icons.handshake_outlined,
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                
                // 3. Historial (Recibe) - MOVIDO AQUÍ
                InkWell(
                  onTap: () => _mostrarDesglosePagos(),
                  borderRadius: BorderRadius.circular(8),
                  child: _buildStatItem(
                    'Historial',
                    '\$${_grupo!.recaudadoTurno.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _tienePagos => (_grupo?.totalAcumulado ?? 0) > 0.01;

  Widget _buildIniciarSusuBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Susu en Espera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade todos los participantes y asegúrate de que tengan un turno asignado. Cuando estés listo, arranca el Susu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showIniciarSusuDialog(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('INICIAR SUSU', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  void _showIniciarSusuDialog(BuildContext context) {
    if (_miembros.isEmpty || _miembros.length < _grupo!.cantidadParticipantes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acción denegada: Faltan miembros por agregar. Hay ${_miembros.length} de ${_grupo!.cantidadParticipantes}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_miembros.any((m) => m.numeroTurno == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acción denegada: Hay miembros con "Sorteo Pendiente". Por favor, haz el sorteo primero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // NUEVA VALIDACIÓN: Fecha proyectada expirada
    if (_grupo!.fechaInicioProyectada != null) {
      final hoy = DateTime.now();
      final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
      final proyectada = _grupo!.fechaInicioProyectada!;
      final proyectadaSinHora = DateTime(proyectada.year, proyectada.month, proyectada.day);

      if (proyectadaSinHora.isBefore(hoySinHora)) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Fecha Expirada'),
              ],
            ),
            content: Text('La fecha de inicio proyectada (${DateUt.formatearFecha(proyectada)}) ha expirado. ¿Deseas seleccionar una nueva fecha o iniciar hoy?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    _ejecutarInicio(picked);
                  }
                },
                child: const Text('ELEGIR FECHA'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _ejecutarInicio(DateTime.now());
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                child: const Text('INICIAR HOY'),
              ),
            ],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar Susu'),
        content: const Text('¿Deseas que el primer pago correspondiente al ciclo 1 comience exactamente hoy o prefieres elegir un día en específico del calendario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                _ejecutarInicio(picked);
              }
            },
            child: const Text('Elegir Fecha'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _ejecutarInicio(DateTime.now());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Comenzar Hoy'),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarInicio(DateTime fechaInicio) async {
    setState(() => _isLoading = true);
    try {
      await _savingsService.iniciarSusu(_grupo!.id!, fechaInicio);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Susu iniciado con éxito!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showEntregarTurnoConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entregar Recaudación'),
        content: Text('¿Confirmas que ya entregaste el dinero al beneficiario del Turno #${_grupo!.turnoActual}? \n\nEsto reiniciará el contador de la tarjeta para el próximo turno.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _savingsService.entregarTurno(_grupo!.id!);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Turno entregado. Iniciando nuevo ciclo.'), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('CONFIRMAR ENTREGA'),
          ),
        ],
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

  String? _getFechaCobro(MiembroGrupo miembro) {
    if (_grupo!.fechaPrimerPago == null || miembro.numeroTurno == null) return null;
    DateTime startDate = _grupo!.fechaPrimerPago!;
    int i = miembro.numeroTurno!;
    DateTime fechaVencimiento;
    switch (_grupo!.periodo) {
      case PeriodoAhorro.diario: fechaVencimiento = startDate.add(Duration(days: i - 1)); break;
      case PeriodoAhorro.semanal: fechaVencimiento = startDate.add(Duration(days: (i - 1) * 7)); break;
      case PeriodoAhorro.quincenal: fechaVencimiento = startDate.add(Duration(days: (i - 1) * 15)); break;
      case PeriodoAhorro.mensual: fechaVencimiento = DateTime(startDate.year, startDate.month + (i - 1), startDate.day); break;
    }
    return '${fechaVencimiento.day.toString().padLeft(2, '0')}/${fechaVencimiento.month.toString().padLeft(2, '0')}/${fechaVencimiento.year}';
  }

  Widget _buildMiembroItem(MiembroGrupo miembro) {
    final bool esTurnoActual = _grupo != null && miembro.numeroTurno == _grupo!.turnoActual;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: esTurnoActual ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esTurnoActual 
          ? const BorderSide(color: AppColors.primaryGreen, width: 2)
          : BorderSide.none,
      ),
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
            backgroundColor: esTurnoActual ? AppColors.primaryGreen : AppColors.primaryGreen.withOpacity(0.1),
            child: Text(
              miembro.numeroTurno != null 
                  ? '${miembro.numeroTurno}'
                  : (miembro.nombreCliente ?? '?').substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: esTurnoActual ? Colors.white : AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  miembro.nombreCliente ?? 'Cargando...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (esTurnoActual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RECIBE',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Cuota: \$${miembro.montoCuota.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
               Text(
                'Recibe: \$${miembro.montoMetaPersonal.toStringAsFixed(2)}', // TERMINOLOGÍA ACTUALIZADA
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (_getFechaCobro(miembro) != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Fecha de cobro: ${_getFechaCobro(miembro)}',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'asignar':
                  _showAsignarNumeroDialog(miembro);
                  break;
                case 'intercambiar':
                  _showIntercambiarNumeroDialog(miembro);
                  break;
                case 'whatsapp':
                  _enviarWhatsAppMiembro(miembro);
                  break;
                case 'eliminar':
                   if (miembro.totalAportado > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se puede eliminar un miembro que ya tiene abonos registrados'))
                    );
                  } else {
                    _confirmDeleteMiembro(miembro);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'asignar',
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Asignar número'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'intercambiar',
                enabled: miembro.numeroTurno != null,
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18, color: Colors.orange.shade700),
                    SizedBox(width: 12),
                    Text('Intercambiar número'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.green),
                    SizedBox(width: 12),
                    Text('WhatsApp'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: Colors.red.shade400)),
                  ],
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

  // 🚀 REQUERIMIENTO 11: ENVÍO DE WHATSAPP
  void _enviarWhatsAppMiembro(MiembroGrupo miembro) async {
    final int pagadas = (_cuotasCache[miembro.id]?.where((c) => c.pagada).length ?? 0);
    final int total = _grupo!.cantidadParticipantes;
    final int pendientes = total - pagadas;
    
    // Obtener fecha de turno si existe
    String fechaRecepcion = 'A sorteo';
    if (miembro.numeroTurno != null) {
      final startDate = _grupo!.fechaPrimerPago ?? _grupo!.fechaCreacion;
      DateTime dt;
      switch (_grupo!.periodo) {
        case PeriodoAhorro.diario: dt = startDate.add(Duration(days: miembro.numeroTurno! - 1)); break;
        case PeriodoAhorro.semanal: dt = startDate.add(Duration(days: (miembro.numeroTurno! - 1) * 7)); break;
        case PeriodoAhorro.quincenal: dt = startDate.add(Duration(days: (miembro.numeroTurno! - 1) * 15)); break;
        case PeriodoAhorro.mensual: dt = DateTime(startDate.year, startDate.month + (miembro.numeroTurno! - 1), startDate.day); break;
      }
      fechaRecepcion = DateUt.formatearFecha(dt);
    }

    String mensaje = '';

    if (_grupo!.fechaPrimerPago == null) {
      // Mensaje de confirmación pre-inicio (Susu no iniciado)
      String fechaApertura = 'Fecha Indefinida';
      String horaApertura = '';
      if (_grupo!.fechaInicioProyectada != null) {
        final fp = _grupo!.fechaInicioProyectada!;
        const mesesStr = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
        fechaApertura = '${fp.day} de ${mesesStr[fp.month - 1]}';
        
        final isPm = fp.hour >= 12;
        int hour12 = fp.hour > 12 ? fp.hour - 12 : (fp.hour == 0 ? 12 : fp.hour);
        String minStr = fp.minute > 0 ? ':${fp.minute.toString().padLeft(2, '0')}' : '';
        horaApertura = '  *Hora: $hour12$minStr${isPm ? 'pm' : 'am'}.*';
      }

      double meses = 0;
      if (_grupo!.cantidadParticipantes > 0) {
        switch (_grupo!.periodo) {
          case PeriodoAhorro.diario: meses = _grupo!.cantidadParticipantes / 30; break;
          case PeriodoAhorro.semanal: meses = _grupo!.cantidadParticipantes / 4; break;
          case PeriodoAhorro.quincenal: meses = _grupo!.cantidadParticipantes / 2; break;
          case PeriodoAhorro.mensual: meses = _grupo!.cantidadParticipantes.toDouble(); break;
        }
      }

      String freqStr = _grupo!.periodo == PeriodoAhorro.diario ? 'diarios' :
                       _grupo!.periodo == PeriodoAhorro.semanal ? 'semanales' :
                       _grupo!.periodo == PeriodoAhorro.quincenal ? 'quincenales' : 'mensuales';

      mensaje = "Muy buenos días, escribimos para confirmar su participación en el susú que se va a apertura este *$fechaApertura*.$horaApertura\n\n"
                "Según se registró con un monto de *${miembro.montoCuota.toStringAsFixed(0)}\$ $freqStr | ${_grupo!.cantidadParticipantes} cuotas | ${meses.toStringAsFixed(1).replaceAll('.0', '')} meses.*\n\n"
                "Puede pagar sus cuotas mensuales, quincenales, semanales o diario como le sea más fácil .";

    } else {
      // Mensaje estándar cuando el Susu ya inició
      mensaje = 
        "*Ficha de Participante - Grupo Ahorro*\n\n"
        "Participante: *${miembro.nombreCliente}*\n"
        "Nombre del grupo: *${_grupo!.nombre}*\n\n"
        "*Información del Susu* 📋\n"
        "Frecuencia: *${_grupo!.periodo.name.toUpperCase()}*\n"
        "Moneda: *USD-BCV*\n"
        "Valor objetivo: *\$${_grupo!.metaAhorro.toStringAsFixed(0)}*\n\n"
        "*Compromiso del Participante* 💰\n"
        "Cuota a pagar: *\$${miembro.montoCuota.toStringAsFixed(0)} ${_grupo!.periodo.name}*\n"
        "Total de cuotas a pagar: *${_grupo!.cantidadParticipantes}*\n"
        "Turno a recibir: *#${miembro.numeroTurno ?? '?'}*\n"
        "Fecha de recepción: *${fechaRecepcion}* ✅\n\n"
        "*Estado de Pagos de las cuotas* 🚨\n"
        "Pagadas: *$pagadas/$total*\n"
        "No pagadas: *0*\n"
        "Pendientes: *$pendientes*";

      // Requerimiento 9: La nota del objetivo que se vea en el registro del miembro
      if (_grupo?.descripcion != null && _grupo!.descripcion!.isNotEmpty) {
        mensaje = "*Ficha de Participante - Grupo Ahorro*\n"
                  "Objetivo: *${_grupo!.descripcion}*\n\n" + mensaje.replaceFirst("*Ficha de Participante - Grupo Ahorro*\n\n", "");
      }
    }

    // Limpiar teléfono del miembro
    String? telefono = miembro.telefonoCliente;

    if (telefono == null || telefono.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El miembro no tiene un número de teléfono registrado')),
        );
      }
      return;
    }

    try {
      await WhatsappService.abrirWhatsApp(
        telefono: telefono,
        mensaje: mensaje,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir WhatsApp: $e')),
        );
      }
    }
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

    return SizedBox(
      height: 130, // Más espacio para la estética
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cuotas.length,
        itemBuilder: (context, index) {
          final c = cuotas[index];
          // Detectar si es la cuota de su propio turno y el grupo dice que no paga
          final bool isExenta = (_grupo?.usuarioRecibeNoPaga ?? false) && c.numeroCuota == miembro.numeroTurno;
          
          final bool tieneSaldo = c.pendiente > 0.01 && !isExenta;
          
          final bool isAtrasada = !c.pagada && !isExenta &&
                                 c.fechaVencimiento.isBefore(DateTime.now().subtract(const Duration(days: 1)));
          
          final Color statusColor = isExenta 
              ? Colors.blueGrey 
              : (c.pagada ? AppColors.success : (isAtrasada ? Colors.red : Colors.orange));
          
          return InkWell(
            onTap: tieneSaldo ? () => _showPayCuotaDialog(miembro, c) : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 135,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isExenta ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '#${c.numeroCuota}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isExenta)
                        const Icon(Icons.lock, color: Colors.blueGrey, size: 14)
                      else if (c.pagada) 
                        const Icon(Icons.check_circle, color: AppColors.success, size: 14)
                      else if (isAtrasada)
                        const Icon(Icons.error, color: Colors.red, size: 14)
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${(isExenta ? c.montoEsperado : (tieneSaldo ? c.pendiente : c.montoPagado)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isExenta ? Colors.blueGrey : (tieneSaldo ? (isAtrasada ? Colors.red.shade800 : Colors.black87) : AppColors.success),
                    ),
                  ),
                  Text(
                    isExenta ? 'TURNO RECIBO' : (tieneSaldo ? 'RESTANTE' : 'COMPLETADO'),
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 0.5,
                      color: isExenta ? Colors.blueGrey.shade300 : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateUt.formatearFecha(c.fechaVencimiento),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDesglosePagos() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Historial de Aportes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _savingsService.getAportesGrupo(widget.grupoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay aportes todavía'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final a = docs[idx];
                      final m = a['Miembros_Grupo'];
                      
                      // Extraer nombre (puede venir como objeto o lista dependiendo del join)
                      String nombre = 'Miembro desacoplado';
                      if (m != null && m['Clientes'] != null) {
                        final cli = m['Clientes'];
                        if (cli is List && cli.isNotEmpty) {
                          nombre = cli[0]['nombre'] ?? nombre;
                        } else if (cli is Map) {
                          nombre = cli['nombre'] ?? nombre;
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                          child: const Icon(Icons.receipt_long, color: AppColors.primaryGreen),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateUt.formatearFecha(DateTime.parse(a['fecha_aporte']))} - ${a['metodo_pago']}'),
                        trailing: Text(
                          '\$${(a['monto'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 15),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            comprobantePath: comprobante, // 👈 PASAR EL CAPTURE
          );

          try {
            await _savingsService.saveAporte(aporte, cuotaId: cuota.id);
            if (mounted) {
              // ACTUALIZACIÓN OPTIMISTA LOCAL
              setState(() {
                final cached = _cuotasCache[miembro.id!];
                if (cached != null) {
                  final idx = cached.indexWhere((c) => c.id == cuota.id);
                  if (idx != -1) {
                    cached[idx] = cached[idx].copyWith(pagada: true, montoPagado: monto);
                  }
                }
              });

              _loadData(); // Recargar balances globales en segundo plano
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pago registrado correctamente'), backgroundColor: AppColors.success),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al registrar pago: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showAsignarNumeroDialog(MiembroGrupo miembro) {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden asignar turnos porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Calcular turnos ocupados excluyendo al miembro actual
    final Set<int> usedTurns = _miembros
        .where((m) => m.numeroTurno != null && m.id != miembro.id)
        .map((m) => m.numeroTurno!)
        .toSet();
    
    List<int> availableTurns = [];
    for (int i = 1; i <= _grupo!.cantidadParticipantes; i++) {
      if (!usedTurns.contains(i)) availableTurns.add(i);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar Turno a ${miembro.nombreCliente}'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableTurns.isEmpty
              ? const Text('No hay turnos disponibles en este grupo.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableTurns.length,
                  itemBuilder: (ctx, idx) {
                    final t = availableTurns[idx];
                    final bool isCurrent = t == miembro.numeroTurno;
                    return ListTile(
                      leading: Icon(isCurrent ? Icons.check_circle : Icons.circle_outlined, 
                        color: isCurrent ? AppColors.primaryGreen : Colors.grey),
                      title: Text('Turno $t'),
                      onTap: () {
                        Navigator.pop(context);
                        _updateMemberTurn(miembro, t);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ],
      ),
    );
  }

  void _showIntercambiarNumeroDialog(MiembroGrupo miembro) {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden intercambiar turnos porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (miembro.numeroTurno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este miembro no tiene un turno asignado para intercambiar.')),
      );
      return;
    }

    final otrosConTurno = _miembros.where((m) => m.id != miembro.id && m.numeroTurno != null).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intercambiar Turno'),
        content: SizedBox(
          width: double.maxFinite,
          child: otrosConTurno.isEmpty
              ? const Text('No hay otros miembros con turnos asignados para realizar un intercambio.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intercambiar turno #${miembro.numeroTurno} de ${miembro.nombreCliente} con:',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: otrosConTurno.length,
                        itemBuilder: (ctx, idx) {
                          final otro = otrosConTurno[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                              child: Text('${otro.numeroTurno}', style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
                            ),
                            title: Text(otro.nombreCliente ?? 'N/A'),
                            onTap: () {
                              Navigator.pop(context);
                              _intercambiarTurnos(miembro, otro);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ],
      ),
    );
  }

  Future<void> _updateMemberTurn(MiembroGrupo miembro, int? turno) async {
    setState(() => _isLoading = true);
    try {
      await _savingsService.updateMiembro(miembro.copyWith(numeroTurno: turno));
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turno asignado correctamente'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar turno: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _intercambiarTurnos(MiembroGrupo m1, MiembroGrupo m2) async {
    setState(() => _isLoading = true);
    try {
      await _savingsService.intercambiarTurnos(m1, m2);
      
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Turnos intercambiados con éxito!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al intercambiar: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAddMemberDialog() {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden añadir miembros porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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
    bool isSaving = false; // Estado de carga
    Map<String, dynamic>? selectedClientData;

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
    final double divisor = _grupo!.usuarioRecibeNoPaga 
        ? (_grupo!.cantidadParticipantes - 1).toDouble() 
        : _grupo!.cantidadParticipantes.toDouble();
    
    final double cuotaSugerida = divisor > 0 ? (_grupo!.metaAhorro / divisor) : 0;
    bool usaCuotaManual = false;

    final TextEditingController cuotaController = TextEditingController(
      text: cuotaSugerida.toStringAsFixed(2),
    );

    // Listener para actualizar la meta automáticamente basado en la cuota
    void updateMeta() {
      final double c = double.tryParse(cuotaController.text) ?? 0;
      final double m = c * divisor;
      final String mStr = m.toStringAsFixed(2);
      if (metaDialogController.text != mStr) {
        metaDialogController.text = mStr;
      }
    }
    
    // Listener para actualizar la cuota automáticamente basada en la meta
    void updateCuota() {
      final double m = double.tryParse(metaDialogController.text) ?? 0;
      if (divisor > 0) {
        final double c = m / divisor;
        final String cStr = c.toStringAsFixed(2);
        if (cuotaController.text != cStr) {
          cuotaController.text = cStr;
        }
      }
    }
    
    // Eliminamos los addListener para usar onChanged directamente en los TextField
    // cuotaController.addListener(updateMeta);
    // metaDialogController.addListener(updateCuota);

    
    // Ejecutar cálculo inicial
    updateMeta();


    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) => AlertDialog(
          title: Text(showCreateForm 
            ? 'Nuevo Cliente' 
            : (selectedClientData != null ? 'Configurar Miembro' : 'Añadir Miembro')),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_grupo?.descripcion != null && !showCreateForm && selectedClientData == null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Objetivo: ${_grupo!.descripcion}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. SELECCIÓN DE CLIENTE O BUSCADOR
                  if (!showCreateForm) ...[
                    if (selectedClientData == null) ...[
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
                              leading: const Icon(Icons.person_outline),
                              title: Text(c['nombre']),
                              subtitle: Text(c['telefono'] ?? 'Sin telefono'),
                              trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                              onTap: () {
                                setDialogState(() {
                                  selectedClientData = c;
                                  results = [];
                                  query = '';
                                });
                              },
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
                      
                      const Divider(),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => showCreateForm = true),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('CREAR NUEVO CLIENTE'),
                      ),
                    ] else ...[
                      // Cliente seleccionado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primaryGreen,
                              radius: 16,
                              child: Icon(Icons.person, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedClientData!['nombre'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    selectedClientData!['telefono'] ?? 'Sin teléfono',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setDialogState(() => selectedClientData = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // FORMULARIO NUEVO CLIENTE
                    const Text('Datos del Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setDialogState(() => showCreateForm = false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Volver a buscar'),
                    ),
                  ],

                  // 2. CONFIGURACIÓN DEL MIEMBRO (Solo si hay cliente o es nuevo)
                  if (selectedClientData != null || showCreateForm) ...[
                    const Divider(height: 32),
                    const Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Configuración del Suzú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    
                    // Selección de tipo de cuota mediante Checkbox
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Usar monto personalizado (Otro)', style: const TextStyle(fontSize: 13)),
                      subtitle: !usaCuotaManual 
                          ? Text('Cuota actual del grupo: \$${cuotaSugerida.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))
                          : null,
                      value: usaCuotaManual,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) {
                        setDialogState(() {
                          usaCuotaManual = val!;
                          if (!usaCuotaManual) {
                            cuotaController.text = cuotaSugerida.toStringAsFixed(2);
                            updateMeta();
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: cuotaController,
                      decoration: InputDecoration(
                        labelText: 'Monto de Cuota', 
                        prefixText: '\$ ', 
                        border: const OutlineInputBorder(),
                        enabled: usaCuotaManual,
                        filled: !usaCuotaManual,
                        fillColor: !usaCuotaManual ? Colors.grey.shade100 : null,
                      ),
                      onChanged: (val) => updateMeta(),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: metaDialogController,
                      decoration: InputDecoration(
                        labelText: 'Meta Personal (Recibe) - ${divisor.toInt()} cuotas', 
                        prefixText: '\$ ', 
                        border: const OutlineInputBorder(),
                        enabled: usaCuotaManual,
                        filled: !usaCuotaManual,
                        fillColor: !usaCuotaManual ? Colors.grey.shade100 : null,
                        helperText: 'Calculado: Cuota x ${divisor.toInt()}',
                      ),
                      onChanged: (val) => updateCuota(),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    const Text('Asignar Turno (Opcional):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_grupo!.cantidadParticipantes, (index) {
                        final t = index + 1;
                        final isOccupied = usedTurns.contains(t);
                        final isSelected = selectedTurn == t;
                        
                        return ChoiceChip(
                          label: Text('T$t'),
                          selected: isSelected,
                          onSelected: isOccupied 
                            ? null 
                            : (val) {
                                setDialogState(() {
                                  selectedTurn = val ? t : null;
                                });
                              },
                          selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryGreen : (isOccupied ? Colors.grey : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: articuloController,
                      decoration: const InputDecoration(
                        labelText: '¿Qué comprará? (Nota)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            if (selectedClientData != null || showCreateForm)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 40),
                ),
                onPressed: isSaving 
                  ? null 
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        if (showCreateForm) {
                          if (nameController.text.isEmpty) {
                            setDialogState(() => isSaving = false);
                            return;
                          }
                          final String clientId = await _savingsService.createCliente(
                            nameController.text,
                            phoneController.text,
                            widget.usuarioNombre,
                          );
                          await _procederAnadir(
                            dialogContext,
                            clientId,
                            nameController.text,
                            phoneController.text,
                            metaDialogController,
                            articuloController,
                            cuotaController,
                            selectedTurn,
                          );
                        } else if (selectedClientData != null) {
                          await _procederAnadir(
                            dialogContext,
                            selectedClientData!['id'].toString(),
                            selectedClientData!['nombre'],
                            selectedClientData!['telefono'],
                            metaDialogController,
                            articuloController,
                            cuotaController,
                            selectedTurn,
                          );
                        }
                      } catch (e) {
                        if (stateContext.mounted) {
                          ScaffoldMessenger.of(stateContext).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (stateContext.mounted) {
                          setDialogState(() => isSaving = false);
                        }
                      }
                    },
                child: isSaving 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    ) 
                  : const Text('AÑADIR A LISTA'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _procederAnadir(
    BuildContext dialogContext,
    String clienteId,
    String nombreCliente,
    String? telefonoCliente,
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
      nombreCliente: nombreCliente,
      telefonoCliente: telefonoCliente,
      montoMetaPersonal: metaPersonal,
      fechaIngreso: DateTime.now(),
      articuloDeseado: articulo.isNotEmpty ? articulo : null,
      numeroTurno: selectedTurn,
      montoCuota: cuota,
    );

    // REGISTRO INMEDIATO
    await _savingsService.addMiembro(miembro);
    
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    
    _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Miembro registrado correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmDeleteMiembro(MiembroGrupo miembro) {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden eliminar miembros porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Eliminar Miembro'),
          content: Text('¿Estás seguro de que deseas eliminar a ${miembro.nombreCliente} del grupo? \n\nEsta acción eliminará también sus cuotas asociadas.'),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context), 
              child: const Text('CANCELAR')
            ),
            ElevatedButton(
              onPressed: isDeleting 
                ? null 
                : () async {
                    setDialogState(() => isDeleting = true);
                    try {
                      await _savingsService.deleteMiembro(miembro.id!);
                      if (context.mounted) Navigator.pop(context);
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Miembro eliminado'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (context.mounted) setDialogState(() => isDeleting = false);
                    }
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
              ),
              child: isDeleting 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                : const Text('ELIMINAR'),
            ),
          ],
        ),
      ),
    );
  }




  void _showEditGrupoDialog() {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar el grupo porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: FormularioGrupo(
          nombreUsuario: widget.usuarioNombre,
          grupo: _grupo,
          onGuardar: (grupoEditado) async {
            try {
              await _savingsService.updateGrupo(grupoEditado);
              Navigator.pop(context);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grupo actualizado correctamente'), backgroundColor: AppColors.success),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al actualizar el grupo: $e'), backgroundColor: Colors.red),
              );
            }
          },
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

    return 'Turno ${_grupo!.turnoActual}: ${info.nombreProximo} (en ${info.diasRestantes} días)';
  }

  Future<void> _realizarSorteo() async {
    if (_tienePagos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede realizar el sorteo porque ya existen pagos registrados.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
