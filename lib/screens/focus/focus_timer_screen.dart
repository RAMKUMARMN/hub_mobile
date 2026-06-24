// lib/screens/focus/focus_timer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/focus_session.dart';
import '../../themes/app_colors.dart';
import '../../widgets/glass/glass_card.dart';
import '../../services/local/notification_service.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  
  FocusSession? _currentSession;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  int _totalMinutesFocused = 0;
  
  final List<int> _focusDurations = [15, 25, 30, 45, 60];
  int _selectedDuration = 25;
  
  // Motivational messages for completion
  final List<String> _motivationalMessages = [
    '🎯 Amazing focus! You\'re building momentum!',
    '💪 Great job! Every session makes you stronger!',
    '🌟 Fantastic! Your discipline is inspiring!',
    '🔥 You\'re on fire! Keep up the great work!',
    '📈 Excellent progress! You\'re getting better every day!',
    '🧠 Your brain is getting sharper! Keep going!',
    '🚀 What a productive session! You\'re unstoppable!',
    '✨ Brilliant focus! Small steps lead to big achievements!',
    '💎 You\'re building a diamond habit! Stay consistent!',
    '🏆 Champion mindset! Another session conquered!',
  ];
  
  final List<String> _breakMessages = [
    '☕ Time to recharge! Take a short break.',
    '🧘 Stretch and breathe. You\'ve earned it!',
    '💧 Hydrate and refresh for the next session.',
    '🌿 Step away for a moment. Clear your mind.',
    '🎵 Enjoy a quick break. You deserve it!',
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedDuration * 60;
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _remainingSeconds),
    );
    
    _controller.addListener(() {
      if (_controller.isAnimating) {
        setState(() {
          _remainingSeconds = (_selectedDuration * 60) - (_controller.value * _selectedDuration * 60).round();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    if (_isRunning) return;
    
    _currentSession = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      durationSeconds: _selectedDuration * 60,
      taskId: null,  // No task linked
    );
    
    _isRunning = true;
    _controller.forward(from: 0);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1 && mounted) {
        _completeSession();
      } else if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }
  
  void _pauseTimer() {
    if (!_isRunning) return;
    _isRunning = false;
    _controller.stop();
    _timer.cancel();
  }
  
  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _remainingSeconds = _selectedDuration * 60;
      _controller.reset();
    });
  }
  
  void _completeSession() async {
    _pauseTimer();
    
    if (_currentSession != null) {
      final actualSeconds = (_selectedDuration * 60) - _remainingSeconds;
      
      final completedSession = FocusSession(
        id: _currentSession!.id,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        durationSeconds: _currentSession!.durationSeconds,
        actualSeconds: actualSeconds,
        completed: true,
        taskId: null,  // No task linked
      );
      
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addFocusSession(completedSession);
      
      setState(() {
        _completedSessions++;
        _totalMinutesFocused += (actualSeconds / 60).round();
        _isBreak = true;
        _selectedDuration = 5;
        _remainingSeconds = 5 * 60;
        _currentSession = null;
      });
      
      // ✅ Show motivational completion notification
      await _showCompletionNotification(actualSeconds);
      
      // ✅ Show break dialog
      _showBreakDialog();
    }
  }
  
  Future<void> _showCompletionNotification(int actualSeconds) async {
    final minutesFocused = (actualSeconds / 60).round();
    
    // Pick a random motivational message
    final message = _motivationalMessages[DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length];
    
    // Show immediate notification
    // In _showCompletionNotification method
    await NotificationService().showImmediateNotification(  // ✅ Changed to public method
      title: '🎉 Focus Session Complete!',
      body: '$message (${minutesFocused} minutes)',
      payload: 'focus_session_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    // Also show a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $message'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showBreakDialog() {
    // Pick a random break message
    final breakMessage = _breakMessages[DateTime.now().millisecondsSinceEpoch % _breakMessages.length];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.celebration, size: 48, color: AppColors.aiCyan),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Focus Session Complete! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              breakMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.aiCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: AppColors.aiCyan, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Take a 5-minute break',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startBreak();
            },
            child: const Text('Start Break'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
              setState(() {
                _isBreak = false;
                _selectedDuration = 25;
                _remainingSeconds = 25 * 60;
                _controller.duration = Duration(seconds: _remainingSeconds);
                _controller.reset();
              });
            },
            child: const Text('Skip Break'),
          ),
        ],
      ),
    );
  }
  
  void _startBreak() {
    setState(() {
      _isBreak = false;
      _selectedDuration = 25;  // Back to focus mode
      _remainingSeconds = _selectedDuration * 60;
      _controller.duration = Duration(seconds: _remainingSeconds);
      _controller.reset();
    });
    _startTimer();
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Focus Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Timer Circle
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.aiCyan.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.grey.shade800 : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      // Progress ring
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isRunning ? AppColors.aiCyan : Colors.grey,
                          ),
                        ),
                      ),
                      // Time text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRunning ? 'Focusing...' : (_isBreak ? 'Break Time' : 'Ready'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Duration selector
                if (!_isRunning && !_isBreak)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: _focusDurations.map((duration) {
                      return FilterChip(
                        label: Text('$duration min'),
                        selected: _selectedDuration == duration,
                        onSelected: (_) => setState(() {
                          _selectedDuration = duration;
                          _remainingSeconds = duration * 60;
                          _controller.duration = Duration(seconds: _remainingSeconds);
                          _controller.reset();
                        }),
                        backgroundColor: Theme.of(context).cardColor,
                        selectedColor: AppColors.aiCyan.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.aiCyan,
                        labelStyle: TextStyle(
                          color: _selectedDuration == duration ? AppColors.aiCyan : textColor,
                        ),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 48),
                
                // Control buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRunning) ...[
                        ElevatedButton.icon(
                          onPressed: _pauseTimer,
                          icon: const Icon(Icons.pause, size: 20),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.stop, size: 20),
                          label: const Text('Stop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _startTimer,
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Start Focusing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Stats Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.timer, color: AppColors.aiCyan, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '$_completedSessions',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('Sessions', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade400,
                      ),
                      Column(
                        children: [
                          Icon(Icons.trending_up, color: AppColors.aiCyan, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '$_totalMinutesFocused',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Text('Minutes', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}