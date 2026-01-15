import 'package:flutter/material.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/shared/widgets/loading_indicator.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType buttonType;
  final bool isLoading;
  final IconData? iconData;
  final double height;
  final double? width;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonType = ButtonType.primary,
    this.isLoading = false,
    this.iconData,
    this.height = 48.0,
    this.width,
    this.borderRadius = 8.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine button styling based on type
    Color buttonColor;
    Color buttonTextColor;
    Color? borderColor;

    switch (buttonType) {
      case ButtonType.primary:
        buttonColor = backgroundColor ?? AppTheme.primaryColor;
        buttonTextColor = textColor ?? Colors.white;
        borderColor = null;
        break;
      case ButtonType.secondary:
        buttonColor = backgroundColor ?? AppTheme.secondaryColor;
        buttonTextColor = textColor ?? Colors.white;
        borderColor = null;
        break;
      case ButtonType.outline:
        buttonColor = Colors.transparent;
        buttonTextColor = textColor ?? AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        break;
      case ButtonType.text:
        buttonColor = Colors.transparent;
        buttonTextColor = textColor ?? AppTheme.primaryColor;
        borderColor = null;
        break;
    }

    // Disable styles if button is disabled
    if (onPressed == null) {
      buttonColor = buttonType == ButtonType.outline || buttonType == ButtonType.text
          ? Colors.transparent
          : Colors.grey[300]!;
      buttonTextColor = Colors.grey[500]!;
      borderColor = buttonType == ButtonType.outline ? Colors.grey[300] : null;
    }

    // Base button with common properties
    Widget button;
    
    if (buttonType == ButtonType.text) {
      // Text button with no background or padding
      button = TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: buttonTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(text),
      );
    } else {
      // Elevated or outlined button
      button = SizedBox(
        height: height,
        width: width,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
            elevation: buttonType == ButtonType.outline || buttonType == ButtonType.text
                ? 0
                : 1,
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    return isLoading
        ? const LoadingIndicator(color: Colors.white, size: 24)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconData != null) ...[
                Icon(iconData, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          );
  }
}