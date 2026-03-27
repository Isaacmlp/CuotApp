// 📅 WIDGET REUTILIZABLE: Selector de fecha personalizado
import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool readOnly;
  final bool compact; // 👈 NUEVO: Modo compacto para listas

  const CustomDatePicker({
    super.key,
    required this.selectedDate,
    this.onDateSelected,
    required this.label,
    this.firstDate,
    this.lastDate,
    this.readOnly = false,
    this.compact = false,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  Future<void> _selectDate() async {
    if (widget.readOnly || widget.onDateSelected == null) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime firstDate = widget.firstDate ?? DateTime(2000);
      final DateTime lastDate = widget.lastDate ?? DateTime(now.year + 10);

      DateTime initialDate = widget.selectedDate ?? now;
      if (initialDate.isBefore(firstDate)) initialDate = firstDate;
      if (initialDate.isAfter(lastDate)) initialDate = lastDate;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        locale: const Locale('es', 'ES'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade700,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        widget.onDateSelected!(picked);
      }
    } catch (e) {
      debugPrint('Error en CustomDatePicker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDate = widget.selectedDate != null;
    final String formattedDate = hasDate
        ? '${widget.selectedDate!.day.toString().padLeft(2, '0')}/${widget.selectedDate!.month.toString().padLeft(2, '0')}/${widget.selectedDate!.year}'
        : widget.label;

    final isInteractive = !widget.readOnly && widget.onDateSelected != null;

    // Colores premium
    final Color primaryColor = Colors.blue.shade800;
    final Color iconColor = hasDate ? primaryColor : Colors.grey.shade400;
    final Color bgColor = widget.readOnly ? Colors.grey.shade50 : Colors.white;
    final Color borderColor = widget.readOnly ? Colors.grey.shade200 : Colors.blue.shade100.withOpacity(0.5);

    if (widget.compact) {
      return InkWell(
        onTap: isInteractive ? _selectDate : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate.substring(0, hasDate ? 8 : formattedDate.length), 
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                  color: hasDate ? Colors.black87 : Colors.grey.shade500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: isInteractive ? _selectDate : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // REDUCIDO padding vertical
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 0.8, // Borde más fino para un look premium
          ),
          boxShadow: [
            if (isInteractive)
              BoxShadow(
                color: primaryColor.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9, // Reducido para ahorrar espacio
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                      color: hasDate ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isInteractive)
              Icon(
                Icons.unfold_more_rounded, // Icono más moderno para "abrir"
                size: 18,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
