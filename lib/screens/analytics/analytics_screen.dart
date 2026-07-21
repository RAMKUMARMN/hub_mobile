// lib/screens/analytics/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_state.dart';
import '../../models/workspace_items/task.dart';
import '../../themes/app_colors.dart';
import '../../widgets/glass/glass_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    // Get all tasks from all workspaces
    final allItems = appState.getAllWorkspaceItems();
    final allTasks = allItems.whereType<Task>().toList();
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks).toDouble() : 0.0;
    final totalFocusMinutes = appState.totalFocusMinutesToday;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats cards row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tasks Completed',
                    value: '$completedTasks/$totalTasks',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Focus Time',
                    value: '$totalFocusMinutes min',
                    icon: Icons.timer,
                    color: AppColors.aiCyan,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Completion rate card
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Task Completion Rate', style: TextStyle(color: textColor)),
                      Text(
                        '${(completionRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.aiCyan),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completionRate.toDouble(),
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.green,
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Focus trend chart
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Focus Trend (Last 7 Days)', style: TextStyle(color: textColor)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: _buildFocusChart(appState),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Productivity insights
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.aiCyan),
                      SizedBox(width: 8),
                      Text('AI Insights', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_getProductivityInsight(appState)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // ✅ FIXED: Removed context usage
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFocusChart(AppState appState) {
    // Get last 7 days of focus data
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return date;
    });
    
    final focusMinutes = days.map((day) {
      return appState.focusSessions
          .where((s) => s.completed && s.endTime != null &&
                s.endTime!.year == day.year &&
                s.endTime!.month == day.month &&
                s.endTime!.day == day.day)
          .fold(0, (sum, s) => sum + (s.actualSeconds ~/ 60));
    }).toList();
    
    // Handle empty data
    final maxY = focusMinutes.isEmpty ? 10.0 : (focusMinutes.reduce((a, b) => a > b ? a : b).toDouble() + 10.0);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxY,
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: i < focusMinutes.length ? focusMinutes[i].toDouble() : 0,
                color: AppColors.aiCyan,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final index = value.toInt();
                if (index < 0 || index >= weekdays.length) return const Text('');
                return Text(weekdays[index]);
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
  
  String _getProductivityInsight(AppState appState) {
    // ✅ FIXED: Use getAllWorkspaceItems().whereType<Task>()
    final allItems = appState.getAllWorkspaceItems();
    final allTasks = allItems.whereType<Task>().toList();
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final totalFocusMinutes = appState.totalFocusMinutesToday;
    
    if (totalTasks == 0) {
      return '📝 Start by adding some tasks to track your productivity!';
    }
    
    if (completedTasks == totalTasks && totalTasks > 0) {
      return '🎉 Amazing! You\'ve completed all your tasks. Time to celebrate and plan your next goals!';
    }
    
    if (totalFocusMinutes > 60) {
      return '🔥 You\'ve been highly focused today! Keep up the great work.';
    }
    
    if (completedTasks < totalTasks / 2) {
      return '💡 Try using the Focus Timer to tackle your pending tasks one by one.';
    }
    
    return '📈 You\'re making good progress. Complete ${totalTasks - completedTasks} more tasks to finish all.';
  }
}