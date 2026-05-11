import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final EdgeInsets? contentPadding;
  final Color? fillColor;
  final bool filled;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.contentPadding,
    this.fillColor,
    this.filled = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: TextStyle(
        fontSize: 16,
        color: widget.enabled ? null : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Theme.of(context).primaryColor)
            : null,
        suffixIcon: _buildSuffixIcon(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.maxLines > 1 ? 16 : 0,
        ),
        filled: widget.filled,
        fillColor: widget.fillColor ?? (widget.enabled ? null : Colors.grey.shade50),
        counterText: '',
      ),
    );
  }

  // 🔧 LÓGICA: Construir ícono de sufijo (para contraseñas)
  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon),
        onPressed: widget.onSuffixIconPressed,
        color: Theme.of(context).primaryColor,
      );
    }

    if (widget.obscureText) {
      return IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        color: Theme.of(context).primaryColor,
      );
    }

    return null;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}

// 🔧 LÓGICA: Extensiones para tipos comunes de campos
extension CustomTextFieldExtensions on CustomTextField {
  static CustomTextField email({
    TextEditingController? controller,
    String? label,
    String? hint,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Correo Electrónico',
      hint: hint ?? 'ejemplo@correo.com',
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
      validator: validator ?? _validateEmail,
    );
  }

  static CustomTextField password({
    TextEditingController? controller,
    String? label,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Contraseña',
      prefixIcon: Icons.lock,
      obscureText: true,
      onChanged: onChanged,
      validator: validator ?? _validatePassword,
    );
  }

  static CustomTextField phone({
    TextEditingController? controller,
    String? label,
    Function(String)? onChanged,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Teléfono',
      prefixIcon: Icons.phone,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
      maxLength: 10,
    );
  }

  static CustomTextField number({
    TextEditingController? controller,
    String? label,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      prefixIcon: Icons.numbers,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      validator: validator,
    );
  }

  static CustomTextField currency({
    TextEditingController? controller,
    String? label,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      controller: controller,
      label: label ?? 'Monto',
      prefixIcon: Icons.attach_money,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      validator: validator,
    );
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es requerido';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}