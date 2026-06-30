// lib/providers/ai_provider.dart
import 'package:flutter/material.dart';
import '../models/chat/ai_chat.dart';
import '../models/chat/chat_message.dart';
import '../models/workspace/workspace.dart';
import '../services/ai/ai_services.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

  // ✅ Chats organized by workspace ID (kept for sidebar display)
  Map<String, List<AIChat>> _workspaceChats = {};
  AIChat? _currentChat;
  Workspace? _currentWorkspace;
  bool _isTyping = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ RAG / Feature toggles (can be surfaced in the UI)
  bool useRag = false;
  bool webSearch = false;
  bool thinkingMode = true;
  List<String> selectedDocumentIds = [];

  // Suggested prompts based on workspace type
  final Map<String, List<String>> _workspacePrompts = {
    'general': [
      'Summarize my recent activity',
      'What are my priorities today?',
      'Give me a productivity tip',
      'Plan my week',
    ],
    'task': [
      'Review my pending tasks',
      'Create tasks from this conversation',
      'Set reminders for deadlines',
      'Prioritize my workload',
    ],
    'note': [
      'Summarize my notes',
      'Find connections between my notes',
      'Extract action items from notes',
      'Organize notes by topic',
    ],
    'default': [
      'What can you help me with?',
      'Explain a concept',
      'Help me brainstorm',
      'Review my progress',
    ],
  };

  // Getters
  List<AIChat> get currentWorkspaceChats {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    return _workspaceChats[workspaceId] ?? [];
  }

  AIChat? get currentChat => _currentChat;
  Workspace? get currentWorkspace => _currentWorkspace;
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<String> get suggestedPrompts {
    if (_currentWorkspace == null) return _workspacePrompts['default']!;
    return _workspacePrompts['default']!;
  }

  AIProvider() {
    // No local storage load — sessions are fetched from backend per workspace
  }

  // ============ SESSION SYNC WITH BACKEND ============

  /// Load all sessions for the current workspace from the backend.
  Future<void> loadSessionsFromBackend() async {
    _setLoading(true);
    try {
      final response = await _aiService.listSessions();
      if (response['success'] == true) {
        final workspaceId = _currentWorkspace?.id ?? 'general';
        final List<dynamic> rawSessions = response['data'] is List
            ? response['data']
            : [];

        final chats = rawSessions.map((s) {
          return AIChat(
            id: s['id'].toString(),
            workspaceId: workspaceId,
            title: s['title'] ?? 'Chat',
            messages: const [],
            createdAt: s['created_at'] != null
                ? DateTime.parse(s['created_at'].toString())
                : DateTime.now(),
            updatedAt: s['updated_at'] != null
                ? DateTime.parse(s['updated_at'].toString())
                : DateTime.now(),
          );
        }).toList();

        _workspaceChats[workspaceId] = chats;

        if (chats.isNotEmpty) {
          _currentChat = chats.first;
        } else {
          // No sessions exist yet — create one
          await _createSessionOnBackend();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading sessions: $e');
      // Fallback: ensure a local chat shell exists
      _ensureLocalFallbackChat();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch and load messages for the currently active chat.
  Future<void> loadMessagesForCurrentChat() async {
    if (_currentChat == null) return;
    final sessionId = _currentChat!.id;

    // Don't reload if it already has messages
    if (_currentChat!.messages.isNotEmpty) return;

    _setLoading(true);
    try {
      final response = await _aiService.getSessionMessages(sessionId);
      if (response['success'] == true) {
        final List<dynamic> rawMessages = response['data'] is List
            ? response['data']
            : [];

        final messages = rawMessages
            .map((m) => ChatMessage.fromJson(m))
            .toList();

        _updateCurrentChatMessages(messages);
      }
    } catch (e) {
      debugPrint('❌ Error loading messages for session $sessionId: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createSessionOnBackend({String title = 'New Chat'}) async {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final response = await _aiService.createSession(title: title);

    if (response['success'] == true) {
      final data = response['data'];
      final newChat = AIChat(
        id: data['id'].toString(),
        workspaceId: workspaceId,
        title: data['title'] ?? 'New Chat',
        messages: const [],
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'].toString())
            : DateTime.now(),
        updatedAt: data['updated_at'] != null
            ? DateTime.parse(data['updated_at'].toString())
            : DateTime.now(),
      );

      if (!_workspaceChats.containsKey(workspaceId)) {
        _workspaceChats[workspaceId] = [];
      }
      _workspaceChats[workspaceId]!.insert(0, newChat);
      _currentChat = newChat;
      notifyListeners();
    }
  }

  void _ensureLocalFallbackChat() {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    if (!_workspaceChats.containsKey(workspaceId) ||
        _workspaceChats[workspaceId]!.isEmpty) {
      _workspaceChats[workspaceId] = [];
      final shell = AIChat(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        workspaceId: workspaceId,
        title: 'New Conversation',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _workspaceChats[workspaceId]!.add(shell);
      _currentChat = shell;
      notifyListeners();
    }
  }

  // ============ CHAT MANAGEMENT ============

  Future<void> createNewChat() async {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];

    // Reuse if there's already an empty chat at the top
    if (chats.isNotEmpty && chats.first.messages.isEmpty) {
      _currentChat = chats.first;
      notifyListeners();
      return;
    }

    await _createSessionOnBackend();
  }

  void selectChat(AIChat chat) {
    _currentChat = chat;
    notifyListeners();
    // Lazy-load messages from backend
    loadMessagesForCurrentChat();
  }

  Future<void> deleteChat(String chatId) async {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];

    // Optimistic removal
    chats.removeWhere((c) => c.id == chatId);
    if (_currentChat?.id == chatId) {
      _currentChat = chats.isNotEmpty ? chats.first : null;
    }
    notifyListeners();

    // Call the backend (fire-and-forget)
    try {
      await _aiService.deleteSession(chatId);
    } catch (e) {
      debugPrint('❌ Error deleting session $chatId: $e');
    }

    // If no sessions left, create a new one
    if (chats.isEmpty) {
      await _createSessionOnBackend();
    }
  }

  void updateChatTitle(String chatId, String newTitle) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final old = chats[index];
      chats[index] = AIChat(
        id: old.id,
        workspaceId: old.workspaceId,
        title: newTitle,
        messages: old.messages,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      if (_currentChat?.id == chatId) {
        _currentChat = chats[index];
      }
      notifyListeners();
    }
  }

  void setWorkspaceContext(Workspace workspace) {
    if (_currentWorkspace?.id == workspace.id) return;
    _currentWorkspace = workspace;
    _currentChat = null;
    notifyListeners();
    // Fetch sessions for the new workspace
    loadSessionsFromBackend();
  }

  // ============ SEND MESSAGE STREAM ============

  Future<void> sendMessageStream({
    required String message,
    required void Function(String chunk) onChunk,
    String? workspaceId,
    String? chatId,
  }) async {
    if (message.trim().isEmpty) return;

    // Ensure there is an active session
    if (_currentChat == null) {
      await _createSessionOnBackend(title: _aiService.generateLocalTitle(message));
    }
    if (_currentChat == null) {
      _addErrorMessage('Could not create a chat session. Please try again.');
      return;
    }

    final String sessionId = _currentChat!.id;

    // Append the user message locally for instant feedback
    _addMessageToCurrentChat(ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      sender: 'user',
      message: message,
      timestamp: DateTime.now(),
    ));

    _setTyping(true);

    // Prepare the AI message placeholder
    String? aiMessageId;
    bool aiMessageCreated = false;

    try {
      await _aiService.sendMessageStream(
        sessionId: sessionId,
        message: message,
        useRag: useRag,
        webSearch: webSearch,
        thinkingMode: thinkingMode,
        documentIds: selectedDocumentIds.isNotEmpty ? selectedDocumentIds : null,
        onEvent: (event) {
          if (event.containsKey('delta')) {
            final token = event['delta'] as String? ?? '';
            if (token.isEmpty) return;

            if (!aiMessageCreated) {
              aiMessageCreated = true;
              aiMessageId = '${DateTime.now().millisecondsSinceEpoch}_ai';
              _setTyping(false);
              _addMessageToCurrentChat(ChatMessage(
                id: aiMessageId!,
                sender: 'ai',
                message: token,
                timestamp: DateTime.now(),
              ));
            } else {
              _appendDeltaToLastAIMessage(sessionId, token);
            }
            onChunk(token);

          } else if (event.containsKey('thinking')) {
            final thinkToken = event['thinking'] as String? ?? '';
            if (thinkToken.isEmpty) return;
            _appendThinkingToLastAIMessage(sessionId, thinkToken);

          } else if (event.containsKey('sources')) {
            final sources = event['sources'];
            if (sources is List) {
              _attachSourcesToLastAIMessage(sessionId,
                  sources.map((s) => Map<String, dynamic>.from(s)).toList());
            }

          } else if (event.containsKey('error')) {
            debugPrint('❌ Stream event error: ${event['error']}');
          }
        },
      );

      if (!aiMessageCreated) {
        _setTyping(false);
        _addErrorMessage('No response received. Please try again.');
      } else {
        _setTyping(false);
      }
    } catch (e) {
      debugPrint('❌ Stream error: $e');
      _setTyping(false);
      _addErrorMessage('Sorry, I encountered an error. Please try again.');
    }
  }

  // ============ MESSAGE MUTATION HELPERS ============

  void _addMessageToCurrentChat(ChatMessage message) {
    if (_currentChat == null) return;
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final index = chats.indexWhere((c) => c.id == _currentChat!.id);

    if (index != -1) {
      final old = chats[index];
      final updated = AIChat(
        id: old.id,
        workspaceId: old.workspaceId,
        title: old.title == 'New Conversation' && old.messages.isEmpty
            ? _aiService.generateLocalTitle(message.message)
            : old.title,
        messages: [...old.messages, message],
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      chats[index] = updated;
      _currentChat = updated;
    }
    notifyListeners();
  }

  void _updateCurrentChatMessages(List<ChatMessage> messages) {
    if (_currentChat == null) return;
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final index = chats.indexWhere((c) => c.id == _currentChat!.id);
    if (index != -1) {
      final old = chats[index];
      final updated = AIChat(
        id: old.id,
        workspaceId: old.workspaceId,
        title: old.title,
        messages: messages,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      chats[index] = updated;
      _currentChat = updated;
      notifyListeners();
    }
  }

  void _appendDeltaToLastAIMessage(String sessionId, String chunk) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final chatIndex = chats.indexWhere((c) => c.id == sessionId);
    if (chatIndex == -1) return;

    final chat = chats[chatIndex];
    if (chat.messages.isEmpty) return;
    final lastMsg = chat.messages.last;
    if (lastMsg.sender != 'ai') return;

    final updated = ChatMessage(
      id: lastMsg.id,
      sender: lastMsg.sender,
      message: lastMsg.message + chunk,
      timestamp: lastMsg.timestamp,
      isError: lastMsg.isError,
      thinking: lastMsg.thinking,
      sources: lastMsg.sources,
    );

    final updatedMessages = [...chat.messages.sublist(0, chat.messages.length - 1), updated];
    chats[chatIndex] = AIChat(
      id: chat.id,
      workspaceId: chat.workspaceId,
      title: chat.title,
      messages: updatedMessages,
      createdAt: chat.createdAt,
      updatedAt: DateTime.now(),
    );
    if (_currentChat?.id == sessionId) {
      _currentChat = chats[chatIndex];
    }
    notifyListeners();
  }

  void _appendThinkingToLastAIMessage(String sessionId, String thinkChunk) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final chatIndex = chats.indexWhere((c) => c.id == sessionId);
    if (chatIndex == -1) return;

    final chat = chats[chatIndex];
    if (chat.messages.isEmpty) return;
    final lastMsg = chat.messages.last;
    if (lastMsg.sender != 'ai') {
      // Create the AI message placeholder with just the thinking token
      if (!chat.messages.any((m) => m.sender == 'ai')) {
        _setTyping(false);
        _addMessageToCurrentChat(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          sender: 'ai',
          message: '',
          timestamp: DateTime.now(),
          thinking: thinkChunk,
        ));
        return;
      }
      return;
    }

    final updated = ChatMessage(
      id: lastMsg.id,
      sender: lastMsg.sender,
      message: lastMsg.message,
      timestamp: lastMsg.timestamp,
      isError: lastMsg.isError,
      thinking: (lastMsg.thinking ?? '') + thinkChunk,
      sources: lastMsg.sources,
    );

    final updatedMessages = [...chat.messages.sublist(0, chat.messages.length - 1), updated];
    chats[chatIndex] = AIChat(
      id: chat.id,
      workspaceId: chat.workspaceId,
      title: chat.title,
      messages: updatedMessages,
      createdAt: chat.createdAt,
      updatedAt: DateTime.now(),
    );
    if (_currentChat?.id == sessionId) {
      _currentChat = chats[chatIndex];
    }
    notifyListeners();
  }

  void _attachSourcesToLastAIMessage(
      String sessionId, List<Map<String, dynamic>> sources) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final chatIndex = chats.indexWhere((c) => c.id == sessionId);
    if (chatIndex == -1) return;

    final chat = chats[chatIndex];
    if (chat.messages.isEmpty) return;

    // Sources arrive before delta tokens — attach them to a placeholder if needed
    final lastMsg = chat.messages.last;
    if (lastMsg.sender != 'ai') return;

    final updated = ChatMessage(
      id: lastMsg.id,
      sender: lastMsg.sender,
      message: lastMsg.message,
      timestamp: lastMsg.timestamp,
      isError: lastMsg.isError,
      thinking: lastMsg.thinking,
      sources: sources,
    );

    final updatedMessages = [...chat.messages.sublist(0, chat.messages.length - 1), updated];
    chats[chatIndex] = AIChat(
      id: chat.id,
      workspaceId: chat.workspaceId,
      title: chat.title,
      messages: updatedMessages,
      createdAt: chat.createdAt,
      updatedAt: DateTime.now(),
    );
    if (_currentChat?.id == sessionId) {
      _currentChat = chats[chatIndex];
    }
    notifyListeners();
  }

  // ============ FILE UPLOAD ============

  Future<void> uploadFileForAnalysis(String filePath, String fileName) async {
    _setLoading(true);
    try {
      _addMessageToCurrentChat(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'user',
        message: '📎 Uploaded file: $fileName',
        timestamp: DateTime.now(),
      ));
      await Future.delayed(const Duration(seconds: 1));
      _addMessageToCurrentChat(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'ai',
        message: '📄 I\'ve received "$fileName". What would you like me to help you with?',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _addErrorMessage('Error processing file: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ============ CLEAR ============

  void clearCurrentChat() {
    if (_currentChat == null) return;
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final index = chats.indexWhere((c) => c.id == _currentChat!.id);
    if (index != -1) {
      final cleared = AIChat(
        id: _currentChat!.id,
        workspaceId: _currentChat!.workspaceId,
        title: 'New Conversation',
        messages: const [],
        createdAt: _currentChat!.createdAt,
        updatedAt: DateTime.now(),
      );
      chats[index] = cleared;
      _currentChat = cleared;
      notifyListeners();
    }
  }

  // ============ HELPERS ============

  void _addErrorMessage(String message) {
    _addMessageToCurrentChat(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'ai',
      message: message,
      timestamp: DateTime.now(),
      isError: true,
    ));
  }

  void _setTyping(bool typing) {
    _isTyping = typing;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}