// lib/providers/ai_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat/ai_chat.dart';
import '../models/chat/chat_message.dart';
import '../models/workspace/workspace.dart';
import '../services/ai/ai_services.dart';
import '../services/api/document_service.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  final DocumentService _documentService = DocumentService();

  // Maps local chat ID -> backend session UUID
  final Map<String, String> _backendSessionIds = {};

  // Tracks which local chat IDs have at least one uploaded document (enables RAG)
  final Set<String> _sessionsWithDocuments = {};

  String? _currentUserId;

  // ✅ Chats organized by workspace ID
  Map<String, List<AIChat>> _workspaceChats = {};
  AIChat? _currentChat;
  Workspace? _currentWorkspace;
  bool _isTyping = false;
  bool _isLoading = false;
  String? _errorMessage;

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
    _loadChats();
  }

  // ============ USER DATA & STORAGE ============

  Future<void> loadUserData(String userId) async {
    _currentUserId = userId;
    _workspaceChats.clear();
    _backendSessionIds.clear();
    _sessionsWithDocuments.clear();
    _currentChat = null;
    await _loadChats();
  }

  void clearUserData() {
    _currentUserId = null;
    _workspaceChats.clear();
    _backendSessionIds.clear();
    _sessionsWithDocuments.clear();
    _currentChat = null;
    notifyListeners();
  }

  Future<String> _getUserScopedKey(String baseKey) async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return '${baseKey}_$_currentUserId';
    }
    return baseKey;
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('ai_chats');
    final chatsJson = prefs.getString(key);
    if (chatsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(chatsJson);
        _workspaceChats = {};
        decoded.forEach((workspaceId, chats) {
          _workspaceChats[workspaceId] =
              (chats as List).map((c) => AIChat.fromJson(c)).toList();
        });
      } catch (e) {
        debugPrint('Error loading chats: $e');
        _workspaceChats = {};
      }
    } else {
      _workspaceChats = {};
    }

    _ensureWorkspaceHasChats();
    notifyListeners();
  }

  Future<void> _saveChats() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserScopedKey('ai_chats');
    final Map<String, List<Map<String, dynamic>>> allChatsJson = {};
    _workspaceChats.forEach((workspaceId, chats) {
      allChatsJson[workspaceId] = chats.map((c) => c.toJson()).toList();
    });
    await prefs.setString(key, jsonEncode(allChatsJson));
  }

  void _ensureWorkspaceHasChats() {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    if (!_workspaceChats.containsKey(workspaceId) ||
        _workspaceChats[workspaceId]!.isEmpty) {
      _workspaceChats[workspaceId] = [];
      _createNewChat();
    } else {
      _currentChat = _workspaceChats[workspaceId]!.first;
    }
  }

  // ============ CHAT MANAGEMENT ============

  void createNewChat() {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];

    if (chats.isNotEmpty && chats.first.messages.isEmpty) {
      _currentChat = chats.first;
      notifyListeners();
      return;
    }

    _createNewChat();
  }

  void _createNewChat() {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final newChat = AIChat(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      title: 'New Conversation',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!_workspaceChats.containsKey(workspaceId)) {
      _workspaceChats[workspaceId] = [];
    }
    _workspaceChats[workspaceId]!.insert(0, newChat);
    _currentChat = newChat;
    _saveChats();
    notifyListeners();
  }

  void selectChat(AIChat chat) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chatWorkspaceId = chat.workspaceId;

    if (chatWorkspaceId != workspaceId) {
      final workspace = Workspace(
        id: chatWorkspaceId,
        name: chatWorkspaceId,
        type: WorkspaceType.general,
        icon: '📁',
        color: Colors.blue,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      setWorkspaceContext(workspace);
    }

    _currentChat = chat;
    notifyListeners();
  }

  void deleteChat(String chatId) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    chats.removeWhere((c) => c.id == chatId);

    if (_currentChat?.id == chatId) {
      _currentChat = chats.isNotEmpty ? chats.first : null;
      if (chats.isEmpty) {
        _createNewChat();
      }
    }
    _saveChats();
    notifyListeners();
  }

  void updateChatTitle(String chatId, String newTitle) {
    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];
    final index = chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final oldChat = chats[index];
      chats[index] = AIChat(
        id: oldChat.id,
        workspaceId: oldChat.workspaceId,
        title: newTitle,
        messages: oldChat.messages,
        createdAt: oldChat.createdAt,
        updatedAt: DateTime.now(),
      );
      if (_currentChat?.id == chatId) {
        _currentChat = chats[index];
      }
      _saveChats();
      notifyListeners();
    }
  }

  void setWorkspaceContext(Workspace workspace) {
    if (_currentWorkspace?.id == workspace.id) return;

    _currentWorkspace = workspace;

    final workspaceId = workspace.id;
    if (!_workspaceChats.containsKey(workspaceId) ||
        _workspaceChats[workspaceId]!.isEmpty) {
      _workspaceChats[workspaceId] = [];
      _createNewChat();
    } else {
      _currentChat = _workspaceChats[workspaceId]!.first;
    }

    notifyListeners();
  }

  // ============ SEND MESSAGE ============

  /// Non-streaming send — delegates to the streaming path (old /ai/chat removed).
  Future<void> sendMessage(String message, {String? workspaceId}) async {
    await sendMessageStream(
      message: message,
      onChunk: (_) {}, // caller doesn't need individual chunks
      workspaceId: workspaceId,
    );
  }

  // ============ STREAMING ============

  Future<void> sendMessageStream({
    required String message,
    required void Function(String chunk) onChunk,
    String? workspaceId,
    String? chatId,
  }) async {
    if (message.trim().isEmpty) return;

    // Ensure we have a current chat
    if (_currentChat == null) {
      _createNewChat();
    }

    final String chatIdToUse = _currentChat!.id;
    debugPrint('📝 Using chat ID: $chatIdToUse');

    _addMessageToCurrentChat(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      message: message,
      timestamp: DateTime.now(),
    ));

    String? aiMessageId;
    bool aiMessageCreated = false;
    String thinkingBuffer = '';

    _setTyping(true);

    try {
      // --- Resolve or create a backend session UUID ---
      String? backendSessionId = _backendSessionIds[chatIdToUse];
      if (backendSessionId == null) {
        debugPrint('🆕 Creating backend session for local chat: $chatIdToUse');
        backendSessionId = await _aiService.createSession(
          title: _currentChat?.title ?? 'New Chat',
        );
        _backendSessionIds[chatIdToUse] = backendSessionId;
        debugPrint('✅ Backend session created: $backendSessionId');
      }

      // Thinking tokens accumulator — prepended to the AI bubble as a block
      void handleThinking(String chunk) {
        thinkingBuffer += chunk;
        debugPrint('🧠 Thinking: $chunk');
      }

      // Answer (delta) tokens
      void handleDelta(String chunk) {
        debugPrint('📥 Delta chunk: ${chunk.length} chars');

        if (!aiMessageCreated) {
          aiMessageCreated = true;
          aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          _setTyping(false);

          // If we have thinking tokens, prepend them visually
          final initialContent = thinkingBuffer.isNotEmpty
              ? '💭 *Thinking…*\n$thinkingBuffer\n\n---\n$chunk'
              : chunk;

          _addMessageToCurrentChat(ChatMessage(
            id: aiMessageId!,
            sender: 'ai',
            message: initialContent,
            timestamp: DateTime.now(),
          ));
        } else {
          _updateLastMessageWithId(chatIdToUse, chunk);
        }

        onChunk(chunk);
      }

      await _aiService.sendMessageStream(
        sessionId: backendSessionId,
        message: message,
        onDelta: handleDelta,
        onThinking: handleThinking,
        useRag: currentChatHasDocuments, // ← true when session has uploaded docs
        thinkingMode: false,
      );

      if (!aiMessageCreated) {
        _setTyping(false);
        _addErrorMessage('No response received. Please try again.');
      }

      _setTyping(false);
      _saveChats();
    } catch (e) {
      debugPrint('❌ Stream error: $e');
      _setTyping(false);
      _addErrorMessage('Sorry, I encountered an error. Please try again.');
    }
  }

  // ✅ SINGLE METHOD to update last message (merged both versions)
  void _updateLastMessageWithId(String chatId, String chunk) {
    debugPrint('🔍 DEBUG: _updateLastMessageWithId called');
    debugPrint('🔍 DEBUG: chatId = $chatId');
    debugPrint('🔍 DEBUG: chunk = $chunk');

    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];

    debugPrint('🔍 DEBUG: workspaceId = $workspaceId');
    debugPrint('🔍 DEBUG: Available chats = ${chats.map((c) => c.id).toList()}');
    debugPrint('🔍 DEBUG: Current chat = ${_currentChat?.id}');

    final index = chats.indexWhere((c) => c.id == chatId);
    debugPrint('🔍 DEBUG: Index found = $index');

    if (index != -1) {
      final chat = chats[index];
      final messages = chat.messages;
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.sender == 'ai') {
          final updatedMessage = ChatMessage(
            id: lastMessage.id,
            sender: lastMessage.sender,
            message: lastMessage.message + chunk,
            timestamp: lastMessage.timestamp,
            isError: lastMessage.isError,
          );
          messages.removeLast();
          messages.add(updatedMessage);

          chats[index] = AIChat(
            id: chat.id,
            workspaceId: chat.workspaceId,
            title: chat.title,
            messages: messages,
            createdAt: chat.createdAt,
            updatedAt: DateTime.now(),
          );

          if (_currentChat?.id == chatId) {
            _currentChat = chats[index];
          }

          notifyListeners();
        }
      }
    } else {
      debugPrint('⚠️ Chat not found with ID: $chatId');
    }
  }

  // ✅ UPDATED: Add message to current chat
  void _addMessageToCurrentChat(ChatMessage message) {
    if (_currentChat == null) {
      _createNewChat();
    }

    final workspaceId = _currentWorkspace?.id ?? 'general';
    if (!_workspaceChats.containsKey(workspaceId)) {
      _workspaceChats[workspaceId] = [];
    }

    final chats = _workspaceChats[workspaceId]!;
    final index = chats.indexWhere((c) => c.id == _currentChat!.id);

    if (index != -1) {
      final oldChat = chats[index];
      final updatedMessages = [...oldChat.messages, message];
      final updatedChat = AIChat(
        id: oldChat.id,
        workspaceId: oldChat.workspaceId,
        title: oldChat.title == 'New Conversation' && oldChat.messages.isEmpty
            ? _generateTitle(message.message)
            : oldChat.title,
        messages: updatedMessages,
        createdAt: oldChat.createdAt,
        updatedAt: DateTime.now(),
      );
      chats[index] = updatedChat;
      _currentChat = updatedChat;
      _saveChats();
    } else {
      _createNewChat();
      _addMessageToCurrentChat(message);
    }

    notifyListeners();
  }

  String _generateTitle(String firstMessage) {
    if (firstMessage.length > 30) {
      return '${firstMessage.substring(0, 27)}...';
    }
    return firstMessage;
  }

  // ============ FILE UPLOAD ============

  /// Whether the current chat has uploaded documents — enables RAG.
  bool get currentChatHasDocuments =>
      _sessionsWithDocuments.contains(_currentChat?.id);

  /// Upload a file to the backend, scoped to the current chat session for RAG.
  /// On success, marks the session as RAG-enabled so future messages
  /// automatically set use_rag=true.
  Future<void> uploadFileForAnalysis(String filePath, String fileName) async {
    _setLoading(true);

    try {
      // Show user message immediately
      _addMessageToCurrentChat(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'user',
        message: '📎 Uploading: $fileName',
        timestamp: DateTime.now(),
      ));

      // Ensure we have a backend session
      final chatId = _currentChat!.id;
      String? backendSessionId = _backendSessionIds[chatId];
      if (backendSessionId == null) {
        backendSessionId = await _aiService.createSession(
          title: _currentChat?.title ?? 'New Chat',
        );
        _backendSessionIds[chatId] = backendSessionId;
        debugPrint('✅ Created session for upload: $backendSessionId');
      }

      // Upload to backend scoped to this session
      final result = await _documentService.uploadForSession(
        file: File(filePath),
        sessionId: backendSessionId,
        customFileName: fileName,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final processed = data['processed'] as bool? ?? false;

        // Mark this session as having documents (enables RAG)
        _sessionsWithDocuments.add(chatId);

        _addMessageToCurrentChat(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: 'ai',
          message: processed
              ? '✅ "$fileName" uploaded and indexed. RAG is now active — I can answer questions based on this document.'
              : '⏳ "$fileName" uploaded successfully. It\'s being indexed in the background. RAG will be active shortly — ask me anything about it!',
          timestamp: DateTime.now(),
        ));
      } else {
        _addErrorMessage('Upload failed: ${result['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      _addErrorMessage('Error uploading file: ${e.toString()}');
    } finally {
      _setLoading(false);
      _saveChats();
    }
  }

  // ============ HELPER METHODS ============

  void _addErrorMessage(String message) {
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'ai',
      message: message,
      timestamp: DateTime.now(),
      isError: true,
    );
    _addMessageToCurrentChat(errorMessage);
  }

  void clearCurrentChat() {
    if (_currentChat != null) {
      final workspaceId = _currentWorkspace?.id ?? 'general';
      final chats = _workspaceChats[workspaceId] ?? [];
      final index = chats.indexWhere((c) => c.id == _currentChat!.id);

      if (index != -1) {
        final clearedChat = AIChat(
          id: _currentChat!.id,
          workspaceId: _currentChat!.workspaceId,
          title: 'New Conversation',
          messages: [],
          createdAt: _currentChat!.createdAt,
          updatedAt: DateTime.now(),
        );
        chats[index] = clearedChat;
        _currentChat = clearedChat;
        _saveChats();
        notifyListeners();
      }
    }
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