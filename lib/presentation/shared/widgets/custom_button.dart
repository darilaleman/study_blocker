import 'package:flutter/material.dart';

enum CustomButtonVariant { filled, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = CustomButtonVariant.filled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = onPressed == null || isLoading;
    final double paddingVertical = icon != null ? 12.0 : 16.0;

    final contentColor = variant == CustomButtonVariant.filled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    // Componente interno que maneja el contenido adaptativo
    Widget buttonContent;

    if (isLoading) {
      // Evitamos el colapso visual fijando un tamaño consistente al del texto
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    } else {
      buttonContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: isDisabled ? theme.disabledColor : contentColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDisabled ? theme.disabledColor : contentColor,
            ),
          ),
        ],
      );
    }

    if (variant == CustomButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: paddingVertical,
            horizontal: 24,
          ),
          side: BorderSide(
            color: isDisabled
                ? theme.disabledColor.withValues(alpha: 0.3)
                : theme.colorScheme.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: buttonContent,
      );
    }

    return FilledButton(
      onPressed: isDisabled ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          vertical: paddingVertical,
          horizontal: 24,
        ),
        backgroundColor: theme.colorScheme.primary,
        disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: buttonContent,
    );
  }
}
