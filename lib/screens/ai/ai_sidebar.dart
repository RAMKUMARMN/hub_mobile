// lib/screens/ai/ai_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../themes/app_colors.dart';
import '../../providers/app_state.dart';
import '../../models/workspace/workspace.dart';
import '../../models/workspace_items/document.dart';
import 'ai_sidebar_items.dart';
import 'ai_dialogs.dart';

class AISidebar extends StatelessWidget {
  final VoidCallback onClose;

  const AISidebar({super.key, required this.onClose});

  List<Document> _getWorkspaceDocuments(AppState appState, Workspace? workspace) {
    if (workspace == null) return [];
    final items = appState.getItemsForWorkspace(workspace.id);
    return items.whereType<Document>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final appState = Provider.of<AppState>(context);
    final currentWorkspace = workspaceProvider.currentWorkspace;
    final workspaceChats = aiProvider.currentWorkspaceChats;
    final documents = _getWorkspaceDocuments(appState, currentWorkspace);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 340,
                height: double.infinity,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    // Workspace Dropdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: AIWorkspaceDropdown(
                        currentWorkspace: currentWorkspace,
                        onTap: () => showWorkspaceMenu(context, workspaceProvider, aiProvider),
                      ),
                    ),

                    // File Selector Tile
                    AIFileSelectorTile(
                      documents: documents,
                      onTap: () => showFileSelectorBottomSheetWithCallback(
                        context,
                        documents,
                        (count) {
                          // The tile will handle updating its own state
                        },
                      ),
                    ),

                    // Recent Chats
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: 100,
                        ),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'RECENT CHATS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () => aiProvider.createNewChat(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '+ New',
                                  style: TextStyle(
                                    color: AppColors.aiCyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (workspaceChats.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text('No conversations yet'),
                              ),
                            )
                          else
                            ...workspaceChats.map((chat) => AIChatTile(
                                  chat: chat,
                                  isSelected: aiProvider.currentChat?.id == chat.id,
                                  onTap: () {
                                    aiProvider.selectChat(chat);
                                    onClose();
                                  },
                                  onRename: () => showRenameChatDialog(context, chat, aiProvider),
                                  onDelete: () => showDeleteChatConfirmation(context, chat, aiProvider),
                                )),
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