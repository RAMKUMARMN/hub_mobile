import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/todo.dart';
import '../../services/api_service.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final response = await ApiService().dio.get('/todos/');
      setState(() {
        _todos = (response.data as List)
            .map((t) => Todo.fromJson(t as Map<String, dynamic>))
            .toList();
        _isLoading = false;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load todos: ${e.message}';
      });
    }
  }

  Future<void> _toggleComplete(Todo todo) async {
    try {
      await ApiService().dio.put(
        '/todos/${todo.id}/complete',
        data: {'completed': !todo.completed},
      );
      setState(() {
        final idx = _todos.indexWhere((t) => t.id == todo.id);
        if (idx != -1) _todos[idx] = todo.copyWith(completed: !todo.completed);
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.message ?? "Unknown error"}')),
        );
      }
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      await ApiService().dio.delete('/todos/$id');
      setState(() { _todos.removeWhere((t) => t.id == id); });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.message ?? "Unknown error"}')),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;
    try {
      final response = await ApiService().dio.post('/todos/', data: {
        'title': titleCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
      });
      setState(() {
        _todos.insert(0, Todo.fromJson(response.data as Map<String, dynamic>));
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create failed: ${e.message ?? "Unknown error"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _todos.where((t) => !t.completed).toList();
    final done = _todos.where((t) => t.completed).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadTodos, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodos,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pending.isEmpty && done.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: Text('No todos yet. Add your first one!')),
                        ),
                      if (pending.isNotEmpty) ...[
                        Text('Pending (${pending.length})',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...pending.map((t) => _TodoTile(
                              todo: t,
                              onToggle: () => _toggleComplete(t),
                              onDelete: () => _deleteTodo(t.id),
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (done.isNotEmpty) ...[
                        Text('Completed (${done.length})',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ...done.map((t) => _TodoTile(
                              todo: t,
                              onToggle: () => _toggleComplete(t),
                              onDelete: () => _deleteTodo(t.id),
                            )),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_todos',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoTile({required this.todo, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(value: todo.completed, onChanged: (_) => onToggle()),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        subtitle: todo.description != null
            ? Text(todo.description!, style: const TextStyle(color: Colors.grey))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

