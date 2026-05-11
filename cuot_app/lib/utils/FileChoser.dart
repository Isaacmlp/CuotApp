import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<void> buscarArchivo() async {
  // Abre el explorador de archivos nativo
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'doc', 'jpg'], // Opcional: filtrar por extensión
  );

  if (result != null) {
    File file = File(result.files.single.path!);
    print('Ruta del archivo: ${file.path}');
  } else {
    // El usuario canceló la búsqueda
  }
}