// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/local/file_service.dart';
import '../../../services/local/note_service.dart';
import '../../../services/local/task_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/activity_card.dart';
import '../../../widgets/common/bottom_nav.dart';
import '../../../widgets/common/notification_button.dart';
import '../focus/focus_timer_screen.dart';
import '../analytics/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  late FileService _fileService;
  late NoteService _noteService;
  late TaskService _taskService;

  final List<Map<String, dynamic>> quickActions = [
    {"title": "Upload", "icon": Icons.upload_file_rounded},
    {"title": "Ask AI", "icon": Icons.auto_awesome_rounded},
    {"title": "Focus Mode", "icon": Icons.timer_rounded},
    {"title": "Tasks", "icon": Icons.check_circle_outline_rounded},
    {"title": "Analytics", "icon": Icons.bar_chart_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fileService = FileService(context: context);
      _noteService = NoteService(context: context);
      _taskService = TaskService(context: context);
    });
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadAllDataFromBackend();
  }

  void _handleUpload() => _fileService.showUploadDialog();
  void _navigateToAI() => NavigationService.navigateToAI(context);
  
  void _startFocusMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
    );
  }
  
  void _viewTasks() => _taskService.viewTasks();
  
  void _viewAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  void _onNavTap(int index) {
    setState(() => currentIndex = index);
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/workspace');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/ai');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: _onNavTap,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with greeting and notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good ${_getTimeOfDay()},",
                        style: TextStyle(color: secondaryText, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.userName ?? "User",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const NotificationButton(),
                ],
              ),
              
              const SizedBox(height: 36),
              
              // Quick Actions - Horizontal Scrollable Row
              Text(
                "Quick Actions",
                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: quickActions.length,
                  itemBuilder: (context, index) {
                    final action = quickActions[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          switch (action["title"]) {
                            case "Upload":
                              _handleUpload();
                              break;
                            case "Ask AI":
                              _navigateToAI();
                              break;
                            case "Focus Mode":
                              _startFocusMode();
                              break;
                            case "Tasks":
                              _viewTasks();
                              break;
                            case "Analytics":
                              _viewAnalytics();
                              break;
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.aiCyan.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(action["icon"], color: AppColors.aiCyan, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                action["title"],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 36),
              
              // AI Insight Card
              _buildAIInsightCard(),
              
              const SizedBox(height: 36),
              
              // Recent Activity Section
              Text(
                "Recent Activity",
                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Recent Activity List
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final recentActivities = appState.recentActivities
                      .take(5)
                      .map((activity) => activity['description'] as String)
                      .toList();
                  
                  if (recentActivities.isEmpty) {
                    return _buildEmptyActivity();
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivities.length,
                    itemBuilder: (context, index) {
                      final activity = recentActivities[index];
                      return GestureDetector(
                        onTap: () {
                          if (activity.toLowerCase().contains('workspace') ||
                              activity.toLowerCase().contains('item') ||
                              activity.toLowerCase().contains('uploaded') ||
                              activity.toLowerCase().contains('note') ||
                              activity.toLowerCase().contains('task') ||
                              activity.toLowerCase().contains('reminder')) {
                            Navigator.pushNamed(context, '/workspace');
                          } else if (activity.toLowerCase().contains('ai') ||
                              activity.toLowerCase().contains('summary') ||
                              activity.toLowerCase().contains('insight')) {
                            Navigator.pushNamed(context, '/ai');
                          }
                        },
                        child: ActivityCard(title: activity),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity() {
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: secondaryText?.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text("No recent activity", style: TextStyle(color: secondaryText)),
          const SizedBox(height: 8),
          Text("Your actions will appear here", style: TextStyle(color: secondaryText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.aiCyan],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiCyan.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                "AI Insight",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _getAIInsight(),
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _navigateToAI,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                label: const Text(
                  "Ask AI Assistant",
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getAIInsight() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "🌅 Good morning! Start your day by reviewing your top 3 priorities.";
    } else if (hour < 17) {
      return "⚡ Afternoon! Take a 5-minute break to stay focused and productive.";
    } else {
      return "🌙 Evening! Review what you accomplished today and plan for tomorrow.";
    }
  }
}