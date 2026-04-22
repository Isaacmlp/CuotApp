import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';

class FormularioGrupo extends StatefulWidget {
  final GrupoAhorro? grupo;
  final String nombreUsuario;
  final Function(GrupoAhorro) onGuardar;
  final bool isLoading;

  const FormularioGrupo({
    super.key,
    this.grupo,
    required this.nombreUsuario,
    required this.onGuardar,
    this.isLoading = false,
  });

  @override
  State<FormularioGrupo> createState() => _FormularioGrupoState();
}

class _FormularioGrupoState extends State<FormularioGrupo> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _metaController = TextEditingController();
  final TextEditingController _participantesController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController(); // Nueva nota
  
  bool _usuarioRecibeNoPaga = false;
  
  PeriodoAhorro _periodo = PeriodoAhorro.semanal;

  @override
  void initState() {
    super.initState();
    if (widget.grupo != null) {
      _nombreController.text = widget.grupo!.nombre;
      _metaController.text = widget.grupo!.metaAhorro.toString();
      _participantesController.text = widget.grupo!.cantidadParticipantes.toString();
      _descripcionController.text = widget.grupo!.descripcion ?? '';
      _usuarioRecibeNoPaga = widget.grupo!.usuarioRecibeNoPaga;
      _periodo = widget.grupo!.periodo;
    }
    _participantesController.addListener(() { setState(() {}); });
    _metaController.addListener(() { setState(() {}); });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _metaController.dispose();
    _participantesController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.grupo != null ? 'Editar Grupo de Ahorro' : 'Crear Nuevo Grupo de Ahorro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Grupo',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _metaController,
                decoration: const InputDecoration(
                  labelText: 'Recaudación por turno', // TERMINOLOGÍA ACTUALIZADA
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('El Usuario que recibe no Paga', style: TextStyle(fontSize: 14)),
                subtitle: const Text('Los participantes están exentos de aportar su propia cuota cuando reclaman el turno.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _usuarioRecibeNoPaga,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) {
                  setState(() => _usuarioRecibeNoPaga = val ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _participantesController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de Participantes',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Nota del objetivo', // REQUERIMIENTO 9
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Ahorro para electrodomésticos',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              const Text('Frecuencia de Ahorro', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPeriodoSelector(),
              
              const SizedBox(height: 24),
              
              _buildResumenDinamico(),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: widget.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.grupo != null ? 'GUARDAR CAMBIOS' : 'CREAR GRUPO',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    return Wrap(
      spacing: 8,
      children: PeriodoAhorro.values.map((p) {
        String label = p.name.toUpperCase();
        // Traducción rápida para UI
        if (p == PeriodoAhorro.diario) label = 'DIARIO';
        if (p == PeriodoAhorro.semanal) label = 'SEMANAL';
        if (p == PeriodoAhorro.quincenal) label = 'QUINCENAL';
        if (p == PeriodoAhorro.mensual) label = 'MENSUAL';

        return ChoiceChip(
          label: Text(label),
          selected: _periodo == p,
          onSelected: (val) => setState(() => _periodo = p),
          selectedColor: AppColors.primaryGreen.withOpacity(0.2),
          labelStyle: TextStyle(
            color: _periodo == p ? AppColors.primaryGreen : Colors.black87,
            fontWeight: _periodo == p ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResumenDinamico() {
    final metaAhorro = double.tryParse(_metaController.text) ?? 0;
    final int participantes = int.tryParse(_participantesController.text) ?? 0;
    
    // Cálculo condicional de cuotas y montos
    final divisor = _usuarioRecibeNoPaga ? (participantes - 1) : participantes;
    final cuotaEstimada = (participantes > (_usuarioRecibeNoPaga ? 1 : 0)) 
        ? metaAhorro / divisor 
        : 0.0;
        
    final numeroPagos = _usuarioRecibeNoPaga && participantes > 0 
        ? participantes - 1 
        : participantes;

    double meses = 0;
    if (participantes > 0) {
      switch (_periodo) {
        case PeriodoAhorro.diario: meses = participantes / 30; break;
        case PeriodoAhorro.semanal: meses = participantes / 4; break;
        case PeriodoAhorro.quincenal: meses = participantes / 2; break;
        case PeriodoAhorro.mensual: meses = participantes.toDouble(); break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Resumen del Susu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Duración estimada:', meses > 0 ? '${meses.toStringAsFixed(1)} meses aprox.' : '-'),
          _buildInfoRow('Participantes:', participantes > 0 ? '$participantes miembros' : '-'),
          _buildInfoRow('Pagos por persona:', numeroPagos > 0 ? '$numeroPagos cuotas' : '-'),
          const SizedBox(height: 4),
          _buildInfoRow('Frecuencia:', _periodo.name.toUpperCase()),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monto por cuota:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                cuotaEstimada > 0 ? '\$${cuotaEstimada.toStringAsFixed(2)}' : '-',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final grupo = widget.grupo?.copyWith(
        nombre: _nombreController.text,
        metaAhorro: double.parse(_metaController.text),
        periodo: _periodo,
        cantidadParticipantes: int.parse(_participantesController.text),
        descripcion: _descripcionController.text.trim(),
        usuarioRecibeNoPaga: _usuarioRecibeNoPaga,
      ) ?? GrupoAhorro(
        nombre: _nombreController.text,
        metaAhorro: double.parse(_metaController.text),
        tipoAporte: TipoAporte.comun, 
        periodo: _periodo,
        creadoPor: widget.nombreUsuario,
        fechaCreacion: DateTime.now(),
        cantidadParticipantes: int.parse(_participantesController.text),
        fechaPrimerPago: null, 
        descripcion: _descripcionController.text.trim(),
        usuarioRecibeNoPaga: _usuarioRecibeNoPaga,
      );
      widget.onGuardar(grupo);
    }
  }
}
