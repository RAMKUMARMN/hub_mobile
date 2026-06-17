import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_storage_service.dart';

import '../../models/message.dart';
import '../../services/api_service.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;
  final _storage = LocalStorageService();

 @override
  void initState() {
    super.initState();
    _loadCachedSessions();
    _loadSessions();
  }

  Future<void> _loadCachedSessions() async {
    final cached = await _storage.getRecentSessions();

    if (!mounted || cached.isEmpty) return;

    setState(() {
      _sessions = cached;
      _isLoading = false;
    });
  }

  Future<void> _loadSessions() async {
    try {
      final response = await ApiService().dio.get('/chat/sessions');
      final sessions = (response.data as List)
      .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
      .toList();

  setState(() {
    _sessions = sessions;
    _isLoading = false;
    _error = null;
  });

  await _storage.saveRecentSessions(sessions);
    } on DioException catch (e) {
        final cached = await _storage.getRecentSessions();

        setState(() {
          _sessions = cached;
          _isLoading = false;
          _error = cached.isEmpty ? 'No cached chats available' : null;
        });
      }
  }

  Future<void> _newSession() async {
    setState(() { _isCreating = true; });
    try {
      final response = await ApiService().dio.post(
        '/chat/sessions',
        data: {'title': 'New Chat'},
      );
      final session = ChatSession.fromJson(
        response.data as Map<String, dynamic>,
      );

      _sessions.insert(0, session);

      await _storage.saveRecentSessions(_sessions);

      if (mounted) {
        context.push('/chat/${session.id}');
      }

      await _loadSessions();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: ${e.message ?? "Unknown error"}')),
        );
      }
    } finally {
      if (mounted) setState(() { _isCreating = false; });
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await ApiService().dio.delete('/chat/sessions/$id');
      setState(() { _sessions.removeWhere((s) => s.id == id); });
      await _storage.saveRecentSessions(_sessions);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.message ?? "Unknown error"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      FilledButton(onPressed: _loadSessions, child: const Text('Retry')),
                    ],
                  ),
                )
              : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No conversations yet'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isCreating ? null : _newSession,
                            icon: const Icon(Icons.add),
                            label: const Text('Start a Chat'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                              ),
                              title: Text(session.title),
                              subtitle: Text(
                                _formatDate(session.updatedAt),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteSession(session.id),
                              ),
                              onTap: () => context.push('/chat/${session.id}'),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_chat_sessions',
        onPressed: _isCreating ? null : _newSession,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
