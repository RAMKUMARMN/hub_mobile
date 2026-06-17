// lib/screens/ai/ai_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';
import 'ai_chat_bubble.dart';
import 'ai_suggested_prompts.dart';
import 'ai_file_upload.dart';
import 'ai_sidebar_overlay.dart';  // Changed from ai_sidebar.dart
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
    }
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
    await aiProvider.sendMessage(text);
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

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;

    return WillPopScope(
      onWillPop: () async {
        if (_isSidebarVisible) {
          _closeSidebar();
          return false;
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return false;
        }
        return true;
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
            // Workspace indicator
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu, size: 18, color: AppColors.aiCyan),
                    const SizedBox(width: 4),
                    Text(
                      workspaceProvider.currentWorkspace?.name ?? 'General',
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                    Icon(Icons.arrow_drop_down, color: secondaryText, size: 18),
                  ],
                ),
              ),
            ),
           
            // Clear chat button
            if (aiProvider.currentChat?.messages.isNotEmpty == true)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => aiProvider.clearCurrentChat(),
                tooltip: 'Clear chat',
              ),
          ],
        ),
        body: Stack(
          children: [
            // Main chat area
            Column(
              children: [
                // Chat messages area
                Expanded(
                  child: aiProvider.isLoading
                      ? _buildLoadingShimmer()
                      : aiProvider.currentChat?.messages.isEmpty == true
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: (aiProvider.currentChat?.messages.length ?? 0) + 
                                        (aiProvider.isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                final messages = aiProvider.currentChat?.messages ?? [];
                                
                                if (aiProvider.isTyping && index == messages.length) {
                                  return _buildTypingIndicator();
                                }
                                
                                final message = messages[index];
                                return AIChatBubble(
                                  message: message.message,
                                  isUser: message.isUser,
                                  timestamp: message.timestamp,
                                  isError: message.isError,
                                  onCopy: () => _copyToClipboard(message.message),
                                );
                              },
                            ),
                ),
                
                // Suggested prompts (only when no messages)
                if (aiProvider.currentChat?.messages.isEmpty == true && !aiProvider.isTyping)
                  AISuggestedPrompts(
                    prompts: aiProvider.suggestedPrompts,
                    onPromptSelected: _sendMessage,
                  ),
                
                // Input area
                _buildInputArea(cardColor, textColor, secondaryText, aiProvider),
              ],
            ),
            
            // Sidebar overlay
            if (_isSidebarVisible)
              AISidebarOverlay(onClose: _closeSidebar),
            
            // File upload overlay
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

  Widget _buildInputArea(Color? cardColor, Color? textColor, Color? secondaryText, AIProvider aiProvider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // File upload button
            GestureDetector(
              onTap: () => _showFileUploadOptions(aiProvider),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.attach_file, size: 22, color: AppColors.aiCyan),
              ),
            ),
            const SizedBox(width: 8),
            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(color: textColor),
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: "Ask SmartHub AI...",
                    hintStyle: TextStyle(color: secondaryText?.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: secondaryText, size: 18),
                            onPressed: () => _controller.clear(),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: aiProvider.isTyping ? null : () => _sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: aiProvider.isTyping ? Colors.grey : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: aiProvider.isTyping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFileUploadOptions(AIProvider aiProvider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AIFileUpload(
        onFileSelected: (filePath, fileName) async {
          Navigator.pop(context);
          setState(() => _isUploading = true);
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
      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildEmptyState() {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppColors.aiCyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a conversation',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me about your tasks, notes, or anything\nin your workspace',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiCyan),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading AI Assistant...',
            style: TextStyle(color: secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiCyan),
            ),
            const SizedBox(width: 14),
            Text(
              "AI is thinking...",
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}