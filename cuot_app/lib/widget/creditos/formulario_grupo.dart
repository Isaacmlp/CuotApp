import 'package:flutter/material.dart';
import 'package:cuot_app/theme/app_colors.dart';
import 'package:cuot_app/Model/grupo_ahorro_model.dart';

class FormularioGrupo extends StatefulWidget {
  final String nombreUsuario;
  final Function(GrupoAhorro) onGuardar;
  final bool isLoading;

  const FormularioGrupo({
    super.key,
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
  DateTime? _fechaPrimerPago;
  
  PeriodoAhorro _periodo = PeriodoAhorro.semanal;

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
                'Crear Nuevo Grupo de Ahorro',
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
              
              const Text('Fecha inicio de pago', style: TextStyle(fontWeight: FontWeight.bold)), // REQUERIMIENTO 2
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                onTap: _seleccionarFecha,
                decoration: InputDecoration(
                  labelText: 'Fecha del Primer Pago',
                  hintText: 'Selecciona una fecha',
                  prefixIcon: const Icon(Icons.calendar_month),
                  border: const OutlineInputBorder(),
                  suffixIcon: _fechaPrimerPago != null ? const Icon(Icons.check_circle, color: AppColors.primaryGreen) : null,
                ),
                controller: TextEditingController(
                  text: _fechaPrimerPago == null
                      ? ''
                      : '${_fechaPrimerPago!.day}/${_fechaPrimerPago!.month}/${_fechaPrimerPago!.year}',
                ),
                validator: (value) =>
                    _fechaPrimerPago == null ? 'Selecciona la fecha inicial' : null,
              ),
              
              const SizedBox(height: 48),
              
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
                    : const Text(
                        'CREAR GRUPO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  void _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Permitir un poco de retroceso por si acaso
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.darkGrey,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaPrimerPago = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final grupo = GrupoAhorro(
        nombre: _nombreController.text,
        metaAhorro: double.parse(_metaController.text),
        tipoAporte: TipoAporte.comun, // Por defecto común como se pidió quitar el selector
        periodo: _periodo,
        creadoPor: widget.nombreUsuario,
        fechaCreacion: DateTime.now(),
        cantidadParticipantes: int.parse(_participantesController.text),
        fechaPrimerPago: _fechaPrimerPago,
        descripcion: _descripcionController.text.trim(),
      );
      widget.onGuardar(grupo);
    }
  }
}
