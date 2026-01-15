import 'package:flutter/material.dart';
import 'package:sacco_mobile/app/app_theme.dart';
import 'package:sacco_mobile/shared/widgets/app_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(
                text: retryButtonText ?? 'Try Again',
                onPressed: onRetry,
                iconData: Icons.refresh,
                buttonType: ButtonType.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}