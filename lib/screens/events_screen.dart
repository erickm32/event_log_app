import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/event_tile.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event>? _events;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _events == null;
      _error = null;
    });
    try {
      final events = await context.read<ApiService>().getEvents();
      if (mounted) setState(() { _events = events; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not reach the server.'; _loading = false; });
    }
  }

  Future<void> _openDetail(Event event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final event = await Navigator.of(context).push<Event>(
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (event != null && mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );
            await _openDetail(event);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _events!.isEmpty
                      ? _EmptyView(onRefresh: _load)
                      : ListView.separated(
                          itemCount: _events!.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) => EventTile(
                            event: _events![i],
                            onTap: () => _openDetail(_events![i]),
                          ),
                        ),
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No events yet.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              const Text(
                'Pull down to refresh.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
