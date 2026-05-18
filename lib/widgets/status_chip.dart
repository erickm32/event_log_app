import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (Colors.amber.shade700, 'Pending'),
      'processing' => (Colors.blue.shade600, 'Processing'),
      'processed' => (Colors.green.shade600, 'Processed'),
      'failed' => (Colors.red.shade600, 'Failed'),
      _ => (Colors.grey.shade600, status),
    };

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
