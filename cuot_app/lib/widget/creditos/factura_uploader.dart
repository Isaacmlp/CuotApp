import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FacturaUploader extends StatefulWidget {
  final Function(File?) onFacturaSeleccionada;

  const FacturaUploader({super.key, required this.onFacturaSeleccionada});

  @override
  State<FacturaUploader> createState() => _FacturaUploaderState();
}

class _FacturaUploaderState extends State<FacturaUploader> {
  File? _facturaFile;
  String? _nombreArchivo;
  final ImagePicker _picker = ImagePicker();

  // 🔧 LÓGICA: Seleccionar imagen de la galería
  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _facturaFile = File(image.path);
          _nombreArchivo = image.name;
        });
        widget.onFacturaSeleccionada(_facturaFile);
      }
    } catch (e) {
      print('Error seleccionando imagen: $e');
      _mostrarError('No se pudo seleccionar la imagen');
    }
  }

  // 🔧 LÓGICA: Tomar foto con la cámara
  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _facturaFile = File(image.path);
          _nombreArchivo = 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
        widget.onFacturaSeleccionada(_facturaFile);
      }
    } catch (e) {
      print('Error tomando foto: $e');
      _mostrarError('No se pudo tomar la foto');
    }
  }

  // 🔧 LÓGICA: Seleccionar PDF
  Future<void> _seleccionarPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() {
          _facturaFile = File(result.files.single.path!);
          _nombreArchivo = result.files.single.name;
        });
        widget.onFacturaSeleccionada(_facturaFile);
      }
    } catch (e) {
      print('Error seleccionando PDF: $e');
      _mostrarError('No se pudo seleccionar el PDF');
    }
  }

  // 🔧 LÓGICA: Mostrar diálogo de opciones
  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarDeGaleria();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Seleccionar PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarPDF();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔧 LÓGICA: Eliminar factura seleccionada
  void _eliminarFactura() {
    setState(() {
      _facturaFile = null;
      _nombreArchivo = null;
    });
    widget.onFacturaSeleccionada(null);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Factura/Foto',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),

        // Área de selección/vista previa
        Container(
          width: 190,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _facturaFile == null
              ? _buildEmptyState()
              : _buildFilePreview(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
  // Verificar que el método existe
  return GestureDetector(
    onTap: () {
      try {
        _mostrarOpciones();
      } catch (e) {
        print('Error en _mostrarOpciones: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    },
    child: Center( // 👈 1. Envolver en Center para centrar horizontalmente
      child: Container(
        //height: 165, // Altura fija (la puedes ajustar)
        // width: double.infinity, // 👈 2. QUITAR esto para que no ocupe todo el ancho
        
        // 👇 3. OPCIONES PARA CONTROLAR EL ANCHO:
        
        // Opción A: Ancho fijo (ej: 300 píxeles)
        width: 150, 
        
        // Opción B: Porcentaje del ancho de la pantalla
        // width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho
        
        // Opción C: Sin ancho definido (se ajusta al contenido)
        // (comenta las opciones A y B si eliges esta)
        
        margin: const EdgeInsets.symmetric(
          horizontal: 20, // Margen horizontal
          vertical: 8,    // Margen vertical
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 👈 4. IMPORTANTE: Para que la columna no ocupe más espacio del necesario
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_upload_outlined, 
              size: 48, 
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Toca para subir la factura',
              style: TextStyle(
                fontSize: 16, 
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center, // 👈 5. Centrar texto por si es muy largo
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG o PNG (Max. 10MB)',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFilePreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              if (_nombreArchivo?.toLowerCase().contains('.pdf') ?? false)
                Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)
              else if (_facturaFile != null)
                Image.file(
                  _facturaFile!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 8),
              Text(
                _nombreArchivo ?? 'Factura',
                style: TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _mostrarOpciones,
                    icon: Icon(Icons.refresh),
                    label: Text('Cambiar'),
                  ),
                  SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _eliminarFactura,
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}