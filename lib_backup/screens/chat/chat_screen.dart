import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _streamingContent = '';
  bool _isStreaming = false;
  bool _useRag = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await ApiService().dio.get('/chat/sessions/${widget.sessionId}/messages');
      final list = (response.data as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      setState(() { _messages.addAll(list); });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isStreaming) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: widget.sessionId,
        role: 'user',
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      ));
      _streamingContent = '';
      _isStreaming = true;
    });
    _scrollToBottom();

    // Real SSE streaming via http package
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final uri = Uri.parse('${AppConfig.apiUrl}/chat/sessions/${widget.sessionId}/messages');

    try {
      final request = http.Request('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode({'content': content, 'use_rag': _useRag});

      final response = await http.Client().send(request);
      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

      await for (final line in stream) {
        if (!mounted) break;
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = (json['choices'] as List?)
                    ?.first['delta']?['content'] as String? ??
                json['delta'] as String? ??
                '';
            if (delta.isNotEmpty) {
              setState(() { _streamingContent += delta; });
              _scrollToBottom();
            }
          } catch (_) {
            // Non-JSON SSE lines (comments etc.) — skip
          }
        }
      }
    } catch (e) {
      debugPrint('SSE error: $e');
      setState(() { _streamingContent = 'Error: could not reach the AI service.'; });
    }

    final fullContent = _streamingContent;
    setState(() {
      _isStreaming = false;
      _streamingContent = '';
      if (fullContent.isNotEmpty) {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: widget.sessionId,
          role: 'assistant',
          content: fullContent,
          createdAt: DateTime.now().toIso8601String(),
        ));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/chat'),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RAG', style: TextStyle(fontSize: 12)),
              Switch(value: _useRag, onChanged: (v) => setState(() { _useRag = v; })),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isStreaming ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isStreaming && index == _messages.length) {
                  return _MessageBubble(
                    message: ChatMessage(
                      id: 'streaming',
                      sessionId: widget.sessionId,
                      role: 'assistant',
                      content: _streamingContent.isEmpty ? '▋' : _streamingContent,
                      createdAt: DateTime.now().toIso8601String(),
                    ),
                  );
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: FilledButton(
                    onPressed: _isStreaming ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Text('AI', style: TextStyle(fontSize: 10)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isUser
                  ? Text(message.content, style: const TextStyle(color: Colors.white))
                  : MarkdownBody(data: message.content),
            ),
          ),
        ],
      ),
    );
  }
}
