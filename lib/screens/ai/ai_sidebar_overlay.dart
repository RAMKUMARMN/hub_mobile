// lib/screens/ai/ai_sidebar_overlay.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';

class AISidebarOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const AISidebarOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                width: 280,
                height: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // Header with New Chat button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'AI Assistant',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // New Chat button in sidebar
                          IconButton(
                            icon: const Icon(Icons.add_comment_outlined, color: AppColors.aiCyan),
                            onPressed: () {
                              aiProvider.createNewChat();
                              onClose();
                            },
                            tooltip: 'New chat',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    
                    // Workspaces section
                    Expanded(
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('WORKSPACES', style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                ...workspaceProvider.workspaces.map((workspace) => ListTile(
                                  leading: Text(workspace.icon),
                                  title: Text(workspace.name),
                                  selected: aiProvider.currentWorkspace?.id == workspace.id,
                                  selectedTileColor: AppColors.aiCyan.withValues(alpha: 0.1),
                                  onTap: () {
                                    aiProvider.setWorkspaceContext(workspace);
                                    onClose();
                                  },
                                )),
                              ],
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('RECENT CHATS', style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                ...aiProvider.chats.map((chat) => ListTile(
                                  title: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    aiProvider.selectChat(chat);
                                    onClose();
                                  },
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}