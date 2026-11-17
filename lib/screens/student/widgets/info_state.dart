import 'package:flutter/material.dart';

import '../../../app_theme.dart';

class InfoState extends StatelessWidget {
  const InfoState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 15),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      );
}
