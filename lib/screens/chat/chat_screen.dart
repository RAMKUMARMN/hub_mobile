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
  String? _loadError;
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMessages = true;
      _loadError = null;
    });

    try {
      final response = await ApiService().dio.get(
            '/chat/sessions/${widget.sessionId}/messages',
          );

      final data = response.data;

      if (data is! List) {
        throw Exception('Invalid response format.');
      }

      final list = data
          .map(
            (m) => ChatMessage.fromJson(
              m as Map<String, dynamic>,
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _messages.clear();
        _messages.addAll(list);
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');

      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to load messages. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
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
    final uri = Uri.parse(
        '${AppConfig.apiUrl}/chat/sessions/${widget.sessionId}/messages');

    final client = http.Client();

    try {
      final request = http.Request('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.body = jsonEncode({'content': content, 'use_rag': _useRag});

      final response = await client.send(request).timeout(
            const Duration(seconds: 60),
          );
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (!mounted) break;
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = (json['choices'] as List?)?.first['delta']?['content']
                    as String? ??
                json['delta'] as String? ??
                '';
            if (delta.isNotEmpty) {
              if (!mounted) break;
              setState(() {
                _streamingContent += delta;
              });
              _scrollToBottom();
            }
          } catch (_) {
            // Non-JSON SSE lines (comments etc.) — skip
          }
        }
      }
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _streamingContent = 'Request timed out. Please try again.';
      });
    } catch (e) {
      debugPrint('SSE error: $e');

      if (!mounted) return;

      setState(() {
        _streamingContent = 'Unable to reach the AI service.';
      });
    } finally {
      client.close();
    }

    final fullContent = _streamingContent;

    if (!mounted) return;

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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/chat'),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RAG', style: TextStyle(fontSize: 12)),
              Switch(
                  value: _useRag,
                  onChanged: (v) => setState(() {
                        _useRag = v;
                      })),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadMessages,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty && !_isStreaming
                        ? const Center(
                            child: Text(
                              'Start a conversation.',
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _messages.length + (_isStreaming ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isStreaming && index == _messages.length) {
                                return _MessageBubble(
                                  message: ChatMessage(
                                    id: 'streaming',
                                    sessionId: widget.sessionId,
                                    role: 'assistant',
                                    content: _streamingContent.isEmpty
                                        ? '▋'
                                        : _streamingContent,
                                    createdAt: DateTime.now().toIso8601String(),
                                  ),
                                );
                              }

                              return _MessageBubble(
                                message: _messages[index],
                              );
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  ? Text(message.content,
                      style: const TextStyle(color: Colors.white))
                  : Builder(
                      builder: (_) {
                        try {
                          return MarkdownBody(
                            data: message.content,
                            selectable: true,
                          );
                        } catch (_) {
                          return Text(message.content);
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
