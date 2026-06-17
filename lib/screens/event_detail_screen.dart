import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/status_chip.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;
  Timer? _timer;

  static const _pollInterval = Duration(seconds: 2);
  static const _terminalStatuses = {'processed', 'failed'};

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    if (!_terminalStatuses.contains(_event.status)) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _openEditForm() async {
    final updated = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(event: _event),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _event = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('"${_event.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await context.read<ApiService>().deleteEvent(_event.id);
      navigator.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not reach the server.')),
      );
    }
  }

  Future<void> _poll() async {
    try {
      final updated = await context.read<ApiService>().getEvent(_event.id);
      if (!mounted) return;
      setState(() => _event = updated);
      if (_terminalStatuses.contains(updated.status)) {
        _timer?.cancel();
        _timer = null;
      }
    } catch (_) {
      // silently ignore transient poll errors — keep trying
    }
  }

  bool get _isPolling => _timer?.isActive ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_event.name),
        actions: [
          PopupMenuButton<_Action>(
            onSelected: (action) {
              if (action == _Action.edit) {
                _openEditForm();
              } else {
                _confirmDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _Action.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _Action.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: _isPolling
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: StatusChip(status: _event.status)),
          if (_isPolling) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Processing…',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
          const SizedBox(height: 32),
          _DetailTile(
            icon: Icons.label_outline,
            label: 'Name',
            value: _event.name,
          ),
          if (_event.observation != null)
            _DetailTile(
              icon: Icons.notes,
              label: 'Observation',
              value: _event.observation!,
            ),
          if (_event.categoryId != null)
            _DetailTile(
              icon: Icons.category_outlined,
              label: 'Category',
              value: 'Category #${_event.categoryId}',
            ),
          if (_event.processedAt != null)
            _DetailTile(
              icon: Icons.check_circle_outline,
              label: 'Processed at',
              value: _formatDateTime(_event.processedAt!),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} '
        '${_pad(local.hour)}:${_pad(local.minute)}:${_pad(local.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

enum _Action { edit, delete }

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
