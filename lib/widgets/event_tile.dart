import 'package:flutter/material.dart';

import '../models/event.dart';
import 'status_chip.dart';

class EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventTile({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(event.name),
      subtitle: event.observation != null
          ? Text(
              event.observation!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: StatusChip(status: event.status),
    );
  }
}
