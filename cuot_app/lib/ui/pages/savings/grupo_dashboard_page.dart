import 'package:cuot_app/service/savings_service.dart';
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
                        'Total Recaudado', // TERMINOLOGÍA ACTUALIZADA
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
                InkWell(
                  onTap: () => _mostrarDesglosePagos(),
                  borderRadius: BorderRadius.circular(8),
                  child: _buildStatItem(
                    'Recaudado', // POR TURNO
                    '\$${_grupo!.recaudadoTurno.toStringAsFixed(0)}',
                    Icons.payments_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                _buildStatItem(
                  'Meta Turno',
                  '\$${_grupo!.metaAhorro.toStringAsFixed(0)}',
                  Icons.flag,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                _buildStatItem(
                  'Turno',
                  '#${_grupo!.turnoActual}',
                  Icons.tag,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // BOTÓN ENTREGAR NUMERO (REQUERIMIENTO 12)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEntregarTurnoConfirm(),
            icon: const Icon(Icons.handshake_outlined),
            label: Text('Entregar Turno #${_grupo!.turnoActual} a $nombreRecibe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
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
                'Recaudado: \$${miembro.totalAportado.toStringAsFixed(2)}', // TERMINOLOGÍA ACTUALIZADA
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline, 
                  color: miembro.totalAportado > 0 ? Colors.grey.shade400 : Colors.red.shade400
                ),
                onPressed: miembro.totalAportado > 0 
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se puede eliminar un miembro que ya tiene abonos registrados'))
                    )
                  : () => _confirmDeleteMiembro(miembro),
                tooltip: 'Eliminar Miembro',
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                onPressed: () => _enviarWhatsAppMiembro(miembro),
                tooltip: 'Enviar vía WhatsApp',
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

    String mensaje = 
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

    // Limpiar teléfono del miembro
    String? telefono = miembro.telefonoCliente;
    if (telefono != null) {
      telefono = telefono.replaceAll(RegExp(r'[^0-9]'), '');
      // Si el teléfono no tiene código de país y parece ser local (ej: 10 dígitos o similar), 
      // podrías prepender el código de tu país si es necesario, pero wa.me suele manejarlo si está completo.
    }

    final String urlStr = telefono != null && telefono.isNotEmpty
        ? "https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}"
        : "https://wa.me/?text=${Uri.encodeComponent(mensaje)}";
    
    final Uri url = Uri.parse(urlStr);
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
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
          final bool tieneSaldo = c.pendiente > 0.01;
          
          return Container(
            width: 140, // Un poco más ancho para albergar el texto
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: c.pagada 
                ? LinearGradient(
                    colors: [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: c.pagada ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: c.pagada ? AppColors.success.withOpacity(0.3) : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CUOTA #${c.numeroCuota}',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                        color: c.pagada ? AppColors.success : Colors.grey.shade500,
                      ),
                    ),
                    if (c.pagada)
                      const Icon(Icons.verified, color: AppColors.success, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tieneSaldo ? 'RESTAN' : 'PAGADO',
                  style: TextStyle(
                    fontSize: 9,
                    color: tieneSaldo ? Colors.red.shade400 : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${(tieneSaldo ? c.pendiente : c.montoPagado).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tieneSaldo ? Colors.black87 : AppColors.success,
                  ),
                ),
                const Spacer(),
                if (tieneSaldo)
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _showPayCuotaDialog(miembro, c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('PAGAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Al día',
                        style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
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
    final TextEditingController cuotaController = TextEditingController(
      text: _grupo!.cantidadParticipantes > 0 ? (_grupo!.metaAhorro / _grupo!.cantidadParticipantes).toStringAsFixed(2) : '0',
    );

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
                    TextField(
                      controller: metaDialogController,
                      decoration: const InputDecoration(labelText: 'Meta Personal', prefixText: '\$ ', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cuotaController,
                      decoration: const InputDecoration(labelText: 'Monto de Cuota', prefixText: '\$ ', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: selectedTurn,
                      decoration: const InputDecoration(labelText: 'Asignar Turno', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sorteo Pendiente')),
                        ...availableTurns.map((t) => DropdownMenuItem(value: t, child: Text('Turno $t'))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedTurn = val),
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

    // REGISTRO INMEDIATO (REQUERIMIENTO ACTUALIZADO)
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
