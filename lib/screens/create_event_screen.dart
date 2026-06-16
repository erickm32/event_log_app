import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _observationController = TextEditingController();

  // null = still loading, [] = loaded (possibly empty after an error)
  List<Category>? _categories;
  int? _selectedCategoryId;
  Map<String, List<String>> _fieldErrors = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await context.read<ApiService>().getCategories();
      if (mounted) setState(() => _categories = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _categories = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load categories.')),
      );
    }
  }

  Future<void> _showNewCategoryDialog() async {
    final category = await showDialog<Category>(
      context: context,
      builder: (_) => _NewCategoryDialog(api: context.read<ApiService>()),
    );
    if (category != null && mounted) {
      setState(() {
        _categories = [..._categories!, category];
        _selectedCategoryId = category.id;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final event = await context.read<ApiService>().createEvent(
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId,
            observation: _observationController.text.trim().isEmpty
                ? null
                : _observationController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(event);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fieldErrors != null) {
        setState(() {
          _fieldErrors = e.fieldErrors!;
          _submitting = false;
        });
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server.')),
      );
    }
  }

  void _clearFieldError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                errorText: _fieldErrors['name']?.join(', '),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (_) => _clearFieldError('name'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(_selectedCategoryId),
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      errorText: _fieldErrors['category_id']?.join(', '),
                    ),
                    hint: Text(
                      _categories == null ? 'Loading...' : 'Select a category',
                    ),
                    items: (_categories ?? [])
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: _categories == null
                        ? null
                        : (v) {
                            setState(() => _selectedCategoryId = v);
                            _clearFieldError('category_id');
                          },
                    validator: (_) =>
                        _selectedCategoryId == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton.outlined(
                    onPressed:
                        _categories == null ? null : _showNewCategoryDialog,
                    icon: const Icon(Icons.add),
                    tooltip: 'New category',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationController,
              decoration: InputDecoration(
                labelText: 'Observation',
                errorText: _fieldErrors['observation']?.join(', '),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              onChanged: (_) => _clearFieldError('observation'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewCategoryDialog extends StatefulWidget {
  final ApiService api;

  const _NewCategoryDialog({required this.api});

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

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
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final category = await widget.api.createCategory(name: name);
      if (mounted) Navigator.of(context).pop(category);
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
      title: const Text('New Category'),
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
              : const Text('Create'),
        ),
      ],
    );
  }
}
