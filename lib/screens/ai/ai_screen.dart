// lib/screens/ai/ai_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/app_state.dart';  // ✅ UNCOMMENT THIS
import '../../themes/app_colors.dart';
import 'ai_chat_widgets.dart';
import 'ai_input_widgets.dart';
import 'ai_sidebar.dart';
import '../../services/navigation/navigation_service.dart';

class AIScreen extends StatefulWidget {
  final String? initialWorkspaceId;

  const AIScreen({super.key, this.initialWorkspaceId});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSidebarVisible = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _loadWorkspaceData();
    _loadDocuments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeProvider() async {
    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);

    if (widget.initialWorkspaceId != null) {
      final workspace = workspaceProvider.workspaces.firstWhere(
        (w) => w.id == widget.initialWorkspaceId,
        orElse: () => workspaceProvider.currentWorkspace!,
      );
      aiProvider.setWorkspaceContext(workspace);
    } else if (workspaceProvider.currentWorkspace != null) {
      aiProvider.setWorkspaceContext(workspaceProvider.currentWorkspace!);
    } else {
      // No workspace set — load sessions for the general space
      await aiProvider.loadSessionsFromBackend();
    }
  }

  Future<void> _loadWorkspaceData() async {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);

    if (workspaceProvider.workspaces.isEmpty) {
      await workspaceProvider.loadWorkspaces();
    }
  }

  Future<void> _loadDocuments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadAllDataFromBackend();
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

  Future<void> _sendMessage([String? customMessage]) async {
  final text = (customMessage ?? _controller.text).trim();
  if (text.isEmpty) return;

  _controller.clear();
  final aiProvider = Provider.of<AIProvider>(context, listen: false);
  final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);

  // ✅ Use streaming instead of regular send
  await aiProvider.sendMessageStream(
    message: text,
    onChunk: (chunk) {
      // Auto-scroll as new chunks arrive
      _scrollToBottom();
    },
    workspaceId: workspaceProvider.currentWorkspace?.id,
  );
  
  _scrollToBottom();
}

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _closeSidebar() {
    setState(() {
      _isSidebarVisible = false;
    });
  }

  Future<void> _showFileUploadOptions() async {
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AIFileUpload(
        currentWorkspace: workspaceProvider.currentWorkspace,
        onFileSelected: (filePath, fileName) async {
          Navigator.pop(context);
          setState(() => _isUploading = true);
          final aiProvider = Provider.of<AIProvider>(context, listen: false);
          await aiProvider.uploadFileForAnalysis(filePath, fileName);
          setState(() => _isUploading = false);
          _scrollToBottom();
        },
      ),
    );
  }

  void _copyToClipboard(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;
    final currentWorkspace = workspaceProvider.currentWorkspace;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_isSidebarVisible) {
          _closeSidebar();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('AI Assistant'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor),
            onPressed: () => NavigationService.goBack(context),
          ),
          actions: [
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.aiCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu, size: 18, color: AppColors.aiCyan),
                    const SizedBox(width: 4),
                    Text(
                      currentWorkspace?.name ?? 'General',
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                    Icon(Icons.arrow_drop_down, color: secondaryText, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: aiProvider.isLoading
                      ? buildLoadingShimmer()
                      : aiProvider.currentChat?.messages.isEmpty == true
                          ? buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: (aiProvider.currentChat?.messages.length ?? 0) +
                                  (aiProvider.isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                final messages = aiProvider.currentChat?.messages ?? [];

                                if (aiProvider.isTyping && index == messages.length) {
                                  return buildTypingIndicator();
                                }

                                final message = messages[index];
                                return AIChatBubble(
                                  message: message.message,
                                  isUser: message.isUser,
                                  timestamp: message.timestamp,
                                  isError: message.isError,
                                  thinking: message.thinking,
                                  sources: message.sources,
                                  onCopy: () => _copyToClipboard(message.message),
                                );
                              },
                            ),
                ),

                if (aiProvider.currentChat?.messages.isEmpty == true && !aiProvider.isTyping)
                  AISuggestedPrompts(
                    prompts: aiProvider.suggestedPrompts,
                    onPromptSelected: _sendMessage,
                  ),

                AIInputArea(
                  controller: _controller,
                  onSend: _sendMessage,
                  onFileUpload: _showFileUploadOptions,
                  isTyping: aiProvider.isTyping,
                ),
              ],
            ),

            if (_isSidebarVisible) AISidebar(onClose: _closeSidebar),

            if (_isUploading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading and analyzing...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}