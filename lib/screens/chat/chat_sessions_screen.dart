import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/aws_sns_sms_service.dart';
import '../../services/message_service.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  final SmsService _sms = SmsService();
  bool _isCreating = false;
  bool _isSendingSms = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await ApiService().dio.get('/chat/sessions');
      setState(() {
        _sessions = (response.data as List)
            .map((s) => ChatSession.fromJson(s as Map<String, dynamic>))
            .toList();
        _isLoading = false;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load chats: ${e.message}';
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
          SnackBar(content: Text('Failed to create chat: ${e.message ?? "Unknown error"}')),
        );
      }
    } finally {
      if (mounted) setState(() { _isCreating = false; });
    }
  }

  Future<void> _testSms() async {
    if (_isSendingSms) return;
    setState(() => _isSendingSms = true);

    SmsResult outcome;
    try {
      // Resolve the destination from the SNS sandbox — never typed by hand.
      // The logged-in user's stored phone is used only to pick between
      // multiple verified sandbox numbers.
      final stored = await AuthService().getCurrentUser().then((u) => u?.phone);
      final resolved = await _sms.resolveSandboxNumber(userPhone: stored);

      if (resolved == null) {
        outcome = const SmsResult.failure(
            'No verified sandbox number to send to.');
      } else {
        outcome = await _sms.sendSms(
          phone: resolved.phone,
          message: 'Test SMS from CixioHub to ${resolved.source}.',
        );
        if (outcome.success) {
          outcome = SmsResult.success('${outcome.message} (${resolved.source})');
        }
      }
    } on SnsException catch (e) {
      outcome = SmsResult.failure(e.toString());
    } catch (e) {
      outcome = SmsResult.failure('Unexpected error: $e');
    }

    if (!mounted) return;
    setState(() => _isSendingSms = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message),
        duration: const Duration(seconds: 6),
        backgroundColor: outcome.success
            ? Colors.green.shade700
            : Colors.red.shade700,
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    try {
      await ApiService().dio.delete('/chat/sessions/$id');
      setState(() { _sessions.removeWhere((s) => s.id == id); });
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_test_sms',
            onPressed: _isSendingSms ? null : _testSms,
            icon: _isSendingSms
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sms_outlined),
            label: const Text('Test SMS'),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab_chat_sessions',
            onPressed: _isCreating ? null : _newSession,
            icon: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
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
