import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// A ticked list of the health categories Personally reads. Used on the manage
/// screen so the member always sees exactly what is shared.
class DataScopeList extends StatelessWidget {
  const DataScopeList({super.key, required this.labels, this.onDark = false});

  final List<String> labels;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final line = onDark ? AppColors.lineDark : AppColors.lineLight;
    final text = onDark ? AppColors.cream : AppColors.ink;

    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            decoration: BoxDecoration(
              border: Border(
                top: i == 0 ? BorderSide(color: line) : BorderSide.none,
                bottom: i == labels.length - 1
                    ? BorderSide.none
                    : BorderSide(color: line),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check, size: 16, color: text),
                const SizedBox(width: 12),
                Text(labels[i], style: AppType.body(color: text).copyWith(fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }
}
