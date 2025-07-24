import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final int? maxLines;
  final bool enabled;
  final Function(String)? onChanged;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autoFocus;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.autoFocus = false,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        enabled: enabled,
        contentPadding: contentPadding,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autoFocus,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: enabled ? null : Colors.grey[600],
      ),
    );
  }
}