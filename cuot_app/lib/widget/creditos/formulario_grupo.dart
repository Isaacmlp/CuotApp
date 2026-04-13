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
  
  TipoAporte _tipoAporte = TipoAporte.comun;
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
                decoration: InputDecoration(
                  labelText: 'Meta de Ahorro Grupal',
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.flag),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('Tipo de Aporte', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTipoAporteSelector(),
              
              const SizedBox(height: 24),
              
              const Text('Frecuencia de Ahorro', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPeriodoSelector(),
              
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

  Widget _buildTipoAporteSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Común (Todos igual)'),
            selected: _tipoAporte == TipoAporte.comun,
            onSelected: (val) => setState(() => _tipoAporte = TipoAporte.comun),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Diferente (Meta pers.)'),
            selected: _tipoAporte == TipoAporte.diferente,
            onSelected: (val) => setState(() => _tipoAporte = TipoAporte.diferente),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodoSelector() {
    return Wrap(
      spacing: 8,
      children: PeriodoAhorro.values.map((p) {
        return ChoiceChip(
          label: Text(p.name.toUpperCase()),
          selected: _periodo == p,
          onSelected: (val) => setState(() => _periodo = p),
        );
      }).toList(),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final grupo = GrupoAhorro(
        nombre: _nombreController.text,
        metaAhorro: double.parse(_metaController.text),
        tipoAporte: _tipoAporte,
        periodo: _periodo,
        creadoPor: widget.nombreUsuario,
        fechaCreacion: DateTime.now(),
      );
      widget.onGuardar(grupo);
    }
  }
}
