// 📅 WIDGET REUTILIZABLE: Selector de fecha personalizado
import 'package:flutter/material.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  
  const CustomDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.label,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime.now(),
          lastDate: lastDate ?? DateTime.now().add(Duration(days: 365 * 5)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null
                  ? label
                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              style: TextStyle(
                color: selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
            Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}