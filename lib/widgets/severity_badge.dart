import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  static (Color, String, IconData) _props(String s) => switch (s) {
        'LOW' => (
            const Color(0xFF4CAF50),
            'Low',
            Icons.check_circle_outline
          ),
        'MEDIUM' => (const Color(0xFFFF9800), 'Medium', Icons.info_outline),
        'HIGH' => (
            const Color(0xFFF44336),
            'High',
            Icons.warning_amber_rounded
          ),
        'CRITICAL' => (
            const Color(0xFFB71C1C),
            'Critical',
            Icons.dangerous_rounded
          ),
        _ => (Colors.grey, s, Icons.help_outline),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _props(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
