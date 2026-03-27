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

    if (widget.compact) {
      return InkWell(
        onTap: isInteractive ? _selectDate : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: widget.readOnly ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.readOnly ? Colors.grey.shade300 : Colors.grey.shade400,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: widget.readOnly ? Colors.grey.shade400 : Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate.substring(0, hasDate ? 8 : formattedDate.length), // dd/mm/yy
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                  color: hasDate ? Colors.black87 : Colors.grey.shade400,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.readOnly ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.readOnly ? Colors.grey.shade300 : Colors.grey.shade400,
            width: 1,
          ),
          boxShadow: [
            if (isInteractive)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: widget.readOnly ? Colors.grey.shade400 : Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                      color: hasDate ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isInteractive)
              Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
