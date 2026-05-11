import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class StepDocuments extends StatefulWidget {
  final File? cedulaFile;
  final ValueChanged<File?> onCedulaPicked;

  const StepDocuments({
    super.key,
    required this.cedulaFile,
    required this.onCedulaPicked,
  });

  @override
  State<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends State<StepDocuments> {
  final ImagePicker _picker = ImagePicker();
  String? _nombreArchivo;

  // Lógica: Seleccionar imagen de la galería
  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _nombreArchivo = image.name);
        widget.onCedulaPicked(File(image.path));
      }
    } catch (e) {
      _mostrarError('No se pudo seleccionar la imagen');
    }
  }

  // Lógica: Tomar foto con la cámara
  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _nombreArchivo = 'cedula_${DateTime.now().millisecondsSinceEpoch}.jpg');
        widget.onCedulaPicked(File(image.path));
      }
    } catch (e) {
      _mostrarError('No se pudo tomar la foto');
    }
  }

  // Lógica: Seleccionar PDF
  Future<void> _seleccionarPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() => _nombreArchivo = result.files.single.name);
        widget.onCedulaPicked(File(result.files.single.path!));
      }
    } catch (e) {
      _mostrarError('No se pudo seleccionar el PDF');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  // Dialogo de opciones
  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Subir Cédula de Identidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarDeGaleria();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Seleccionar PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarPDF();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documento de Identidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Por favor, sube una foto clara o un PDF de tu cédula. Este documento es requerido para tu registro.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _mostrarOpciones,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.cedulaFile == null ? Colors.grey.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.cedulaFile == null ? Colors.grey.shade300 : Colors.green.shade300,
                  width: 2,
                  style: widget.cedulaFile == null ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: widget.cedulaFile == null
                  ? Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Toca para subir tu cédula',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        const Text('PDF, JPG o PNG (Max. 10MB)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  : Column(
                      children: [
                        if (_nombreArchivo != null && _nombreArchivo!.toLowerCase().endsWith('.pdf'))
                          const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(widget.cedulaFile!, height: 120, fit: BoxFit.cover),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _nombreArchivo ?? 'cedula_subida',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _mostrarOpciones,
                              icon: const Icon(Icons.refresh, color: Colors.blue),
                              label: const Text('Cambiar', style: TextStyle(color: Colors.blue)),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _nombreArchivo = null);
                                widget.onCedulaPicked(null);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
