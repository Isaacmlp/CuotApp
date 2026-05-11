import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isExpanded;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isExpanded = false,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
    this.height = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 🔧 LÓGICA: Determinar colores según el tipo de botón
    final Color backgroundColor = isOutlined 
        ? Colors.transparent 
        : (color ?? theme.primaryColor);
    
    final Color foregroundColor = isOutlined
        ? (textColor ?? theme.primaryColor)
        : (textColor ?? Colors.white);
    
    final BorderSide borderSide = isOutlined
        ? BorderSide(color: color ?? theme.primaryColor)
        : BorderSide.none;

    // 🔧 LÓGICA: Construir el botón
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: isExpanded ? Size(double.infinity, height) : Size(height * 2, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderSide,
        ),
        elevation: isOutlined ? 0 : 2,
      ),
      child: _buildChild(),
    );

    return button;
  }

  // 🔧 LÓGICA: Construir el contenido del botón (texto, icono o loading)
  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? Colors.grey : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// 🔧 LÓGICA: Extensión para crear botones de forma rápida
extension CustomButtonExtension on CustomButton {
  static CustomButton primary({
    required String text,
    required VoidCallback? onPressed,
    bool isExpanded = false,
    bool isLoading = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isExpanded: isExpanded,
      isLoading: isLoading,
    );
  }

  static CustomButton secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isExpanded = false,
    bool isLoading = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isExpanded: isExpanded,
      isLoading: isLoading,
      isOutlined: true,
    );
  }

  static CustomButton danger({
    required String text,
    required VoidCallback? onPressed,
    bool isExpanded = false,
    bool isLoading = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isExpanded: isExpanded,
      isLoading: isLoading,
      color: Colors.red,
    );
  }

  static CustomButton success({
    required String text,
    required VoidCallback? onPressed,
    bool isExpanded = false,
    bool isLoading = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isExpanded: isExpanded,
      isLoading: isLoading,
      color: Colors.green,
    );
  }
}