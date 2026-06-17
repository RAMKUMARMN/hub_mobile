// lib/providers/ai_provider.dart
import 'package:flutter/material.dart';
import '../models/chat/ai_chat.dart';
import '../models/chat/chat_message.dart';
import '../models/workspace/workspace.dart';
import '../services/ai/ai_services.dart';

class AIProvider extends ChangeNotifier {
  final AIService _aiService = AIService();
  
  List<AIChat> _chats = [];
  AIChat? _currentChat;
  Workspace? _currentWorkspace;
  bool _isTyping = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Suggested prompts based on workspace context
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
  List<AIChat> get chats => _chats;
  AIChat? get currentChat => _currentChat;
  Workspace? get currentWorkspace => _currentWorkspace;
  bool get isTyping => _isTyping;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  List<String> get suggestedPrompts {
    if (_currentWorkspace == null) return _workspacePrompts['default']!;
    
    // Return prompts based on workspace type or content
    return _workspacePrompts['default']!;
  }

  AIProvider() {
    _loadChats();
  }

  // ============ CHAT MANAGEMENT ============
  
  void _loadChats() {
    // Load from local storage or API
    _chats = [];
    
    // Create a default chat if none exists
    if (_chats.isEmpty) {
      _createNewChat();
    }
    
    notifyListeners();
  }

  void _createNewChat() {
    final newChat = AIChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: _currentWorkspace?.id ?? 'general',
      title: 'New Conversation',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _chats.insert(0, newChat);
    _currentChat = newChat;
    notifyListeners();
  }

  void createNewChat() {
    _createNewChat();
  }

  void selectChat(AIChat chat) {
    _currentChat = chat;
    notifyListeners();
  }

  void deleteChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);
    if (_currentChat?.id == chatId && _chats.isNotEmpty) {
      _currentChat = _chats.first;
    } else if (_chats.isEmpty) {
      _createNewChat();
    }
    notifyListeners();
  }

  void updateChatTitle(String chatId, String newTitle) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      _chats[index] = AIChat(
        id: _chats[index].id,
        workspaceId: _chats[index].workspaceId,
        title: newTitle,
        messages: _chats[index].messages,
        createdAt: _chats[index].createdAt,
        updatedAt: DateTime.now(),
      );
      if (_currentChat?.id == chatId) {
        _currentChat = _chats[index];
      }
      notifyListeners();
    }
  }

  void setWorkspaceContext(Workspace workspace) {
    _currentWorkspace = workspace;
    // Optionally filter chats by workspace
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
    // Use AIService directly
    final aiService = AIService();
    final response = await aiService.sendMessage(message, workspaceId: workspaceId);
    
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

  void _addMessageToCurrentChat(ChatMessage message) {
    if (_currentChat == null) {
      _createNewChat();
    }
    
    final updatedMessages = [..._currentChat!.messages, message];
    final updatedChat = AIChat(
      id: _currentChat!.id,
      workspaceId: _currentChat!.workspaceId,
      title: _currentChat!.title,
      messages: updatedMessages,
      createdAt: _currentChat!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    final index = _chats.indexWhere((c) => c.id == _currentChat!.id);
    if (index != -1) {
      _chats[index] = updatedChat;
      _currentChat = updatedChat;
    }
    
    notifyListeners();
  }

  Future<void> _autoGenerateTitle(String firstMessage) async {
    // Generate a short title from the first message
    String title = firstMessage.length > 30 
        ? '${firstMessage.substring(0, 27)}...' 
        : firstMessage;
    
    // Try to get AI-generated title (optional)
    try {
      final aiTitle = await _aiService.generateTitle(firstMessage);
      if (aiTitle.isNotEmpty) {
        title = aiTitle;
      }
    } catch (e) {
      // Use truncated message as title
    }
    
    updateChatTitle(_currentChat!.id, title);
  }

  // ============ FILE UPLOAD FOR AI ============
  
  Future<void> uploadFileForAnalysis(String filePath, String fileName) async {
    _setLoading(true);
    
    try {
      // Upload file to backend for AI analysis
      final response = await _aiService.uploadDocument(filePath, fileName);
      
      if (response['success']) {
        final summary = response['summary'] ?? 'File uploaded successfully';
        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: 'ai',
          message: '📄 I\'ve analyzed "$fileName".\n\n$summary',
          timestamp: DateTime.now(),
        );
        _addMessageToCurrentChat(aiMessage);
      } else {
        _addErrorMessage('Failed to upload file for analysis');
      }
    } catch (e) {
      _addErrorMessage('Error uploading file');
    } finally {
      _setLoading(false);
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
      final clearedChat = AIChat(
        id: _currentChat!.id,
        workspaceId: _currentChat!.workspaceId,
        title: 'New Conversation',
        messages: [],
        createdAt: _currentChat!.createdAt,
        updatedAt: DateTime.now(),
      );
      
      final index = _chats.indexWhere((c) => c.id == _currentChat!.id);
      if (index != -1) {
        _chats[index] = clearedChat;
        _currentChat = clearedChat;
      }
      notifyListeners();
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