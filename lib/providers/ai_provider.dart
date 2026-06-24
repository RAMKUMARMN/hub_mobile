// lib/providers/ai_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat/ai_chat.dart';
import '../models/chat/chat_message.dart';
import '../models/workspace/workspace.dart';
import '../services/ai/ai_services.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();

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

  // ============ STORAGE ============

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getString('ai_chats');
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
    }

    _ensureWorkspaceHasChats();
    notifyListeners();
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<Map<String, dynamic>>> allChatsJson = {};
    _workspaceChats.forEach((workspaceId, chats) {
      allChatsJson[workspaceId] = chats.map((c) => c.toJson()).toList();
    });
    await prefs.setString('ai_chats', jsonEncode(allChatsJson));
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

  Future<void> sendMessage(String message, {String? workspaceId}) async {
    if (message.trim().isEmpty) return;

    _addMessageToCurrentChat(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'user',
      message: message,
      timestamp: DateTime.now(),
    ));
    _setTyping(true);

    try {
      final response = await _aiService.sendMessage(
        message,
        workspaceId: workspaceId ?? _currentWorkspace?.id,
      );

      _addMessageToCurrentChat(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'ai',
        message: response,
        timestamp: DateTime.now(),
      ));
      _setTyping(false);
    } catch (e) {
      _addErrorMessage('Sorry, I encountered an error. Please try again.');
      _setTyping(false);
    }
  }

  // ============ STREAMING ============

 Future<void> sendMessageStream({
  required String message,
  required void Function(String chunk) onChunk,
  String? workspaceId,
  String? chatId,
}) async {
  if (message.trim().isEmpty) return;

  // ✅ Ensure we have a current chat
  if (_currentChat == null) {
    _createNewChat();
  }

  // ✅ Store the chat ID before adding messages
  final String chatIdToUse = _currentChat!.id;
  print('📝 Using chat ID: $chatIdToUse');

  _addMessageToCurrentChat(ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    sender: 'user',
    message: message,
    timestamp: DateTime.now(),
  ));

  // ✅ Don't create/add the AI message yet — wait for the first chunk
  String? aiMessageId;
  bool aiMessageCreated = false;

  _setTyping(true);

  try {
    await _aiService.sendMessageStream(
      message: message,
      onChunk: (chunk) {
        print('📥 Received chunk: ${chunk.length} characters');

        if (!aiMessageCreated) {
          // ✅ First chunk arrived — create the bubble now, turn off typing
          aiMessageCreated = true;
          aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
          _setTyping(false);

          _addMessageToCurrentChat(ChatMessage(
            id: aiMessageId!,
            sender: 'ai',
            message: chunk,
            timestamp: DateTime.now(),
          ));
        } else {
          // ✅ Subsequent chunks — append to the existing bubble
          _updateLastMessageWithId(chatIdToUse, chunk);
        }

        onChunk(chunk);
      },
      workspaceId: workspaceId ?? _currentWorkspace?.id,
      chatId: null,
    );

    // ✅ Edge case: stream completed but produced zero chunks
    if (!aiMessageCreated) {
      _setTyping(false);
      _addErrorMessage('No response received. Please try again.');
    }

    _setTyping(false);
    _saveChats();
  } catch (e) {
    print('❌ Stream error: $e');
    _setTyping(false);
    _addErrorMessage('Sorry, I encountered an error. Please try again.');
  }
}

  // ✅ SINGLE METHOD to update last message (merged both versions)
  void _updateLastMessageWithId(String chatId, String chunk) {
    print('🔍 DEBUG: _updateLastMessageWithId called');
    print('🔍 DEBUG: chatId = $chatId');
    print('🔍 DEBUG: chunk = $chunk');

    final workspaceId = _currentWorkspace?.id ?? 'general';
    final chats = _workspaceChats[workspaceId] ?? [];

    print('🔍 DEBUG: workspaceId = $workspaceId');
    print('🔍 DEBUG: Available chats = ${chats.map((c) => c.id).toList()}');
    print('🔍 DEBUG: Current chat = ${_currentChat?.id}');

    final index = chats.indexWhere((c) => c.id == chatId);
    print('🔍 DEBUG: Index found = $index');

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
      print('⚠️ Chat not found with ID: $chatId');
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