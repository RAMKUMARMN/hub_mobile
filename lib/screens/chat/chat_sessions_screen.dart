import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/chat_cache.dart';
import '../../utils/error_formatter.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_loader.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _backendLoaded = false;
  bool _isOffline = false;
  String? _error;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadCachedSessions();
    _loadSessions();
  }

  Future<void> _loadCachedSessions() async {
    final cached = await ChatCache.loadSessions();
    if (!mounted || _backendLoaded || cached.isEmpty) return;
    setState(() {
      _sessions = cached;
      _isLoading = false;
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  Future<void> _loadSessions() async {
    try {
      final response = await ApiService().dio.get('/chat/sessions');
      if (!mounted) return;
      _backendLoaded = true;
      final list = (response.data as List)
          .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
          .toList();
      setState(() {
        _sessions = list;
        _isLoading = false;
        _error = null;
        _listKey = GlobalKey<AnimatedListState>();
      });
      await ChatCache.saveSessions(list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_sessions.isEmpty) {
          _error = ErrorFormatter.format(e);
        } else {
          _isOffline = true;
        }
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
      final session = ChatSession.fromJson(response.data as Map<String, dynamic>);
      if (mounted) context.push('/chat/${session.id}');
      await _loadSessions();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Failed to create chat.'))),
        );
      }
    } finally {
      if (mounted) setState(() { _isCreating = false; });
    }
  }

  Future<void> _deleteSession(String id) async {
    try {
      await ApiService().dio.delete('/chat/sessions/$id');
      await ChatCache.deleteMessages(id);
      
      final idx = _sessions.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final session = _sessions[idx];
        _sessions.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx,
          (context, animation) => _buildItem(session, animation),
          duration: const Duration(milliseconds: 200),
        );
      }
      await ChatCache.saveSessions(_sessions);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Delete failed.'))),
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
                      child: AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.all(16),
                        initialItemCount: _sessions.length,
                        itemBuilder: (context, index, animation) {
                          return _buildItem(_sessions[index], animation);
                        },
                      ),
                    ),
          ),
        ],
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

  Widget _buildItem(ChatSession session, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
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
        ),
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
