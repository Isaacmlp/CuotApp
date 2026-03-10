import 'package:flutter/material.dart';
import 'document_tile.dart';

class StepDocuments extends StatelessWidget {
  const StepDocuments({
    super.key,
    required this.cedulaPath,
    required this.facturaPath,
    required this.onCedulaPicked,
    required this.onFacturaPicked,
  });

  final String? cedulaPath;
  final String? facturaPath;
  final ValueChanged<String> onCedulaPicked;
  final ValueChanged<String> onFacturaPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentTile(
          titulo: 'Cédula de identidad',
          descripcion: 'Adjunta foto o PDF de tu cédula',
          seleccionado: cedulaPath,
          onTap: () async {
            // TODO: file picker / image picker
            onCedulaPicked('cedula_ejemplo.pdf');
          },
        ),
        const SizedBox(height: 12),
        DocumentTile(
          titulo: 'Facturas',
          descripcion: 'Adjunta facturas relacionadas',
          seleccionado: facturaPath,
          onTap: () async {
            // TODO: file picker / image picker
            onFacturaPicked('facturas_ejemplo.pdf');
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Los documentos serán revisados para validar tus cuotas.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
