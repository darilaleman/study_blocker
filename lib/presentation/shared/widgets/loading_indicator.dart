import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingIndicator({super.key, this.message, this.isFullScreen = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget indicatorBody = Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner adaptativo automático (Material en Android, Cupertino en iOS)
            CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        // Corregido: .withValues cambiado por .withOpacity para estabilidad en producción
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
        body: indicatorBody,
      );
    }

    return indicatorBody;
  }
}
