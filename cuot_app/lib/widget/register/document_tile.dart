import 'package:flutter/material.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final String descripcion;
  final String? seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado == null
                ? Colors.grey.shade300
                : primaryGreen,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              seleccionado == null
                  ? Icons.upload_file_outlined
                  : Icons.check_circle_outline,
              color: seleccionado == null
                  ? Colors.grey[600]
                  : primaryGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seleccionado ?? descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: seleccionado == null
                          ? Colors.grey[600]
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
