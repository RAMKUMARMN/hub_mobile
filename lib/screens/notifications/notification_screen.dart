// lib/screens/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../widgets/glass/glass_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'all';
  
  final List<Map<String, dynamic>> _mockNotifications = [
    {
      "id": "1",
      "title": "AI Summary Completed",
      "subtitle": "Your DBMS notes summary is ready.",
      "icon": Icons.auto_awesome_rounded,
      "category": "ai",
      "workspaceId": "General",
      "createdAt": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "id": "2",
      "title": "Task Reminder",
      "subtitle": "Complete internship UI flow today.",
      "icon": Icons.check_circle_outline_rounded,
      "category": "task",
      "workspaceId": "Internship",
      "createdAt": DateTime.now().subtract(const Duration(hours: 5)),
    },
    {
      "id": "3",
      "title": "New File Uploaded",
      "subtitle": "AI Research.pdf added to workspace.",
      "icon": Icons.upload_file_rounded,
      "category": "file",
      "workspaceId": "General",
      "createdAt": DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      "id": "4",
      "title": "Workspace Updated",
      "subtitle": "Internship roadmap edited recently.",
      "icon": Icons.folder_copy_rounded,
      "category": "workspace",
      "workspaceId": "Internship",
      "createdAt": DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') return _mockNotifications;
    return _mockNotifications.where((n) => n['category'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterChips(),
        ),
      ),
      body: _filteredNotifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final item = _filteredNotifications[index];
                return _buildNotificationCard(item, textColor, secondaryText);
              },
            ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'All', 'icon': Icons.notifications_none},
      {'value': 'task', 'label': 'Tasks', 'icon': Icons.check_circle_outline},
      {'value': 'ai', 'label': 'AI', 'icon': Icons.auto_awesome},
      {'value': 'file', 'label': 'Files', 'icon': Icons.upload_file},
      {'value': 'workspace', 'label': 'Workspace', 'icon': Icons.folder},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              avatar: Icon(filter['icon'] as IconData, size: 16),
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter['value'] as String : 'all';
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.aiCyan.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.aiCyan : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, Color? textColor, Color? secondaryText) {
    // ✅ Extract values with proper casting
    final title = item['title'] as String;
    final subtitle = item['subtitle'] as String;
    final icon = item['icon'] as IconData;
    final workspaceId = item['workspaceId'] as String?;
    final createdAt = item['createdAt'] as DateTime;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening notification...'), duration: Duration(seconds: 1)),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.aiCyan.withValues(alpha: 0.2), AppColors.primaryBlue.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.aiCyan, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (workspaceId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.aiCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder_outlined, size: 10, color: AppColors.aiCyan),
                            const SizedBox(width: 4),
                            Text(
                              workspaceId,
                              style: const TextStyle(color: AppColors.aiCyan, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(color: secondaryText, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: secondaryText),
            const SizedBox(height: 16),
            Text('No notifications', style: TextStyle(color: secondaryText, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('When you get notifications, they\'ll appear here', style: TextStyle(color: secondaryText, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}