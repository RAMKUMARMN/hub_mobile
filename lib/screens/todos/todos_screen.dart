import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/todo.dart';
import '../../services/api_service.dart';
import '../../services/todo_cache.dart';
import '../../utils/error_formatter.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_loader.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<Todo> _pending = [];
  List<Todo> _done = [];
  bool _isLoading = true;
  bool _backendLoaded = false;
  bool _isOffline = false;
  String? _error;
  GlobalKey<AnimatedListState> _pendingKey = GlobalKey<AnimatedListState>();
  GlobalKey<AnimatedListState> _doneKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadCachedTodos();
    _loadTodos();
  }

  Future<void> _loadCachedTodos() async {
    final cached = await TodoCache.loadTodos();
    if (!mounted || _backendLoaded || cached.isEmpty) return;
    setState(() {
      _pending = cached.where((t) => !t.completed).toList();
      _done = cached.where((t) => t.completed).toList();
      _isLoading = false;
      _pendingKey = GlobalKey<AnimatedListState>();
      _doneKey = GlobalKey<AnimatedListState>();
    });
  }

  Future<void> _loadTodos() async {
    try {
      final response = await ApiService().dio.get('/todos/');
      if (!mounted) return;
      _backendLoaded = true;
      final list = (response.data as List)
          .map((t) => Todo.fromJson(t as Map<String, dynamic>))
          .toList();
      setState(() {
        _pending = list.where((t) => !t.completed).toList();
        _done = list.where((t) => t.completed).toList();
        _isLoading = false;
        _error = null;
        _pendingKey = GlobalKey<AnimatedListState>();
        _doneKey = GlobalKey<AnimatedListState>();
      });
      await TodoCache.saveTodos(list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_pending.isEmpty && _done.isEmpty) {
          _error = ErrorFormatter.format(e);
        } else {
          _isOffline = true;
        }
      });
    }
  }

  Future<void> _toggleComplete(Todo todo) async {
    try {
      await ApiService().dio.put(
        '/todos/${todo.id}/complete',
        data: {'completed': !todo.completed},
      );
      HapticFeedback.lightImpact();
      
      final updated = todo.copyWith(completed: !todo.completed);
      setState(() {
        if (todo.completed) {
          final idx = _done.indexWhere((t) => t.id == todo.id);
          if (idx != -1) {
            _done.removeAt(idx);
            _doneKey.currentState?.removeItem(idx, (context, anim) => _buildTodoTile(todo, anim), duration: const Duration(milliseconds: 200));
            _pending.insert(0, updated);
            _pendingKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 200));
          }
        } else {
          final idx = _pending.indexWhere((t) => t.id == todo.id);
          if (idx != -1) {
            _pending.removeAt(idx);
            _pendingKey.currentState?.removeItem(idx, (context, anim) => _buildTodoTile(todo, anim), duration: const Duration(milliseconds: 200));
            _done.insert(0, updated);
            _doneKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 200));
          }
        }
      });
      await TodoCache.saveTodos([..._pending, ..._done]);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Failed to update.'))),
        );
      }
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      await ApiService().dio.delete('/todos/$id');
      HapticFeedback.lightImpact();
      
      setState(() {
        final pendingIdx = _pending.indexWhere((t) => t.id == id);
        if (pendingIdx != -1) {
          final t = _pending[pendingIdx];
          _pending.removeAt(pendingIdx);
          _pendingKey.currentState?.removeItem(pendingIdx, (context, anim) => _buildTodoTile(t, anim), duration: const Duration(milliseconds: 200));
        } else {
          final doneIdx = _done.indexWhere((t) => t.id == id);
          if (doneIdx != -1) {
            final t = _done[doneIdx];
            _done.removeAt(doneIdx);
            _doneKey.currentState?.removeItem(doneIdx, (context, anim) => _buildTodoTile(t, anim), duration: const Duration(milliseconds: 200));
          }
        }
      });
      await TodoCache.saveTodos([..._pending, ..._done]);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Delete failed.'))),
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
      final newTodo = Todo.fromJson(response.data as Map<String, dynamic>);
      setState(() {
        _pending.insert(0, newTodo);
        _pendingKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 200));
      });
      await TodoCache.saveTodos([..._pending, ..._done]);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Create failed.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(isOffline: _isOffline),
          Expanded(
            child: _isLoading
                ? const SkeletonLoader()
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
                      if (_pending.isEmpty && _done.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(child: Text('No todos yet. Add your first one!')),
                        ),
                      if (_pending.isNotEmpty) ...[
                        Text('Pending (${_pending.length})',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        AnimatedList(
                          key: _pendingKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: _pending.length,
                          itemBuilder: (context, index, animation) {
                            return _buildTodoTile(_pending[index], animation);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_done.isNotEmpty) ...[
                        Text('Completed (${_done.length})',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        AnimatedList(
                          key: _doneKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: _done.length,
                          itemBuilder: (context, index, animation) {
                            return _buildTodoTile(_done[index], animation);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_todos',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoTile(Todo todo, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _TodoTile(
          todo: todo,
          onToggle: () => _toggleComplete(todo),
          onDelete: () => _deleteTodo(todo.id),
        ),
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

