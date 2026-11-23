import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Komponen representasi empty state, error state, atau informasi umum.
/// Sesuai DESIGN.md section 8 (Interaction and state requirements).
class InfoState extends StatelessWidget {
  const InfoState({
    super.key,
    required this.icon,
    required this.text,
    this.subtext,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
  });

  final IconData icon;
  final String text;
  final String? subtext;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.deep),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 6),
              Text(
                subtext!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.muted,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
