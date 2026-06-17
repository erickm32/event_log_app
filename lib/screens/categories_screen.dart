import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category>? _categories;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _categories == null;
      _error = null;
    });
    try {
      final list = await context.read<ApiService>().getCategories();
      if (mounted) setState(() { _categories = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not reach the server.'; _loading = false; });
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(api: context.read<ApiService>()),
    );
    if (created != null && mounted) {
      setState(() => _categories = [..._categories!, created]);
    }
  }

  Future<void> _openEditDialog(Category category) async {
    final updated = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(
        api: context.read<ApiService>(),
        category: category,
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _categories = [
          for (final c in _categories!)
            if (c.id == updated.id) updated else c,
        ];
      });
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '"${category.name}" will be permanently deleted.',
        ),
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
    try {
      await context.read<ApiService>().deleteCategory(category.id);
      if (mounted) {
        setState(() =>
            _categories = _categories!.where((c) => c.id != category.id).toList());
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not reach the server.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: _categories == null ? null : _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _categories!.isEmpty
                      ? _EmptyView()
                      : ListView.separated(
                          itemCount: _categories!.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final category = _categories![i];
                            return ListTile(
                              title: Text(category.name),
                              trailing: PopupMenuButton<_Action>(
                                onSelected: (action) {
                                  if (action == _Action.edit) {
                                    _openEditDialog(category);
                                  } else {
                                    _confirmDelete(category);
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
                            );
                          },
                        ),
            ),
    );
  }
}

enum _Action { edit, delete }

// ---------------------------------------------------------------------------
// Shared dialog for create and edit
// ---------------------------------------------------------------------------

class _CategoryDialog extends StatefulWidget {
  final ApiService api;
  final Category? category; // null = create mode, non-null = edit mode

  const _CategoryDialog({required this.api, this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _submitting = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Required');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final result = _isEditing
          ? await widget.api.updateCategory(widget.category!.id, name: name)
          : await widget.api.createCategory(name: name);
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.fieldErrors?['name']?.join(', ') ?? e.message;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server.';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Category' : 'New Category'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Name *',
          errorText: _error,
        ),
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No categories yet.',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Tap + to create one.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
