// lib/screens/workspace/workspace_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/workspace_items/task.dart';
import '../../../mixins/loading_state.dart'; 
import '../../../providers/app_state.dart';
import '../../../providers/workspace_provider.dart';
import '../../../services/local/file_service.dart';
import '../../../services/local/note_service.dart';
import '../../../services/local/notification_service.dart';
import '../../../services/api/task_api_service.dart';
import '../../../themes/app_colors.dart';
import '../calendar/calendar_screen.dart';
import 'workspace_content.dart';
import 'workspace_selector.dart';
import 'package:logger/logger.dart';
final logger = Logger();


class WorkspaceScreen extends StatefulWidget {
  final String? initialWorkspaceId;
  
  
  const WorkspaceScreen({super.key, this.initialWorkspaceId});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> with AutomaticKeepAliveClientMixin, LoadingState<WorkspaceScreen> {
  final List<String> _filters = ['all', 'tasks', 'notes', 'files'];
  
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isDeleting = false;

  final List<_UndoItem> _undoStack = [];
  
  // Dialog controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  
  late FileService _fileService;
  late NoteService _noteService;
  final TaskApiService _taskApi = TaskApiService();  // ✅ NEW

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _initializeWorkspace();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeServices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _fileService = FileService(context: context);
    _noteService = NoteService(context: context);
  }

  Future<void> _initializeWorkspace() async {
    setLoading(true);

    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Load workspaces from provider
    await workspaceProvider.loadWorkspaces();
    
    if (widget.initialWorkspaceId != null) {
      workspaceProvider.selectWorkspaceById(widget.initialWorkspaceId!);
    }
    
    // Load items from backend
    await appState.loadAllDataFromBackend();
  
    setLoading(false);
  }

  
  // ✅ UPDATED: Use withLoading() from the mixin
  Future<void> _refreshData() async {
    await withLoading(() async {
      final appState = Provider.of<AppState>(context, listen: false);
      final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      
      await workspaceProvider.loadWorkspaces();
      await appState.loadAllDataFromBackend();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshed!'), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIndices.isEmpty) return;
    
    setState(() => _isDeleting = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    if (workspaceId == null) {
      setState(() => _isDeleting = false);
      return;
    }
    
    final items = appState.getItemsForWorkspace(workspaceId);
    
    final itemsToDelete = _selectedIndices.map((i) {
      final item = items[i];
      return _UndoItem(
        index: i,
        title: item.title,
        subtitle: item.subtitle,
      );
    }).toList();
    
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (var index in sortedIndices) {
      appState.removeWorkspaceItem(index, workspaceId: workspaceId);
    }
    
    _undoStack.add(_UndoItem.multiple(itemsToDelete));
    
    setState(() => _isDeleting = false);
    _isSelectionMode = false;
    _selectedIndices.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${itemsToDelete.length} item${itemsToDelete.length > 1 ? 's' : ''}'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _undoLastDelete(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _undoLastDelete() async {
    if (_undoStack.isEmpty) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id ?? 'general';
    
    final undoItem = _undoStack.removeLast();
    
    if (undoItem.isMultiple) {
      for (var item in undoItem.items!) {
        final restoredItem = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          workspaceId: workspaceId,
          title: item.title,
          subtitle: item.subtitle,
          icon: Icons.description_rounded,
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          dueDate: null,
          reminderAt: null,
          reminderEnabled: false,
          reminderCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        appState.addWorkspaceItem(restoredItem, workspaceId: workspaceId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restored items'), duration: Duration(seconds: 2)),
        );
      }
    } else {
      final restoredItem = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workspaceId: workspaceId,
        title: undoItem.title,
        subtitle: undoItem.subtitle,
        icon: Icons.description_rounded,
        description: '',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: null,
        reminderAt: null,
        reminderEnabled: false,
        reminderCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      appState.addWorkspaceItem(restoredItem, workspaceId: workspaceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored: ${undoItem.title}'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _showCreateOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.aiCyan),
                title: const Text('Create Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddItemDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.notes, color: AppColors.aiCyan),
                title: const Text('Create Note'),
                onTap: () {
                  Navigator.pop(context);
                  _noteService.showCreateNoteDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: AppColors.aiCyan),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  _fileService.showUploadDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.aiCyan),
                title: const Text('Create Workspace'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateWorkspaceDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // lib/screens/workspace/workspace_screen.dart

// Replace the existing _showCreateWorkspaceDialog with this simple version
Future<void> _showCreateWorkspaceDialog() async {
  final controller = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Workspace'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Workspace name'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.isNotEmpty) {
              final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
              final success = await workspaceProvider.createWorkspace(
                controller.text,
                icon: '📁',      // ← Default icon
                color: Colors.blue,  // ← Default color
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workspace created!')),
                  );
                  await _initializeWorkspace();
                }
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

  /// Helper to show DateTime picker for reminders
  Future<DateTime?> _showDateTimePicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return null;
    
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time == null) return null;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAddItemDialog() {
    _titleController.clear();
    _subtitleController.clear();
    
    String selectedPriority = 'medium';
    DateTime? selectedDueDate;
    
    // Reminder state
    bool enableReminder = false;
    DateTime? selectedReminderTime;

    showDialog(
      context: context,
      builder: (context) {
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Create Task", style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task Title
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        hintText: "Task Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    TextField(
                      controller: _subtitleController,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(
                        hintText: "Description (optional)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    
                    // Priority Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPriority,
                          isExpanded: true,
                          hint: const Text('Select Priority'),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('🔵 Low Priority')),
                            DropdownMenuItem(value: 'medium', child: Text('🟡 Medium Priority')),
                            DropdownMenuItem(value: 'high', child: Text('🔴 High Priority')),
                          ],
                          onChanged: (value) => setDialogState(() => selectedPriority = value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Due Date Picker
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDueDate != null 
                            ? 'Due: ${_formatDate(selectedDueDate!)}' 
                            : 'Set due date (optional)',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDueDate = picked);
                        }
                      },
                    ),
                    
                    // Reminder Switch
                    SwitchListTile(
                      title: const Text('Set Reminder'),
                      subtitle: const Text('Get notified before this task'),
                      value: enableReminder,
                      onChanged: (val) {
                        setDialogState(() {
                          enableReminder = val;
                          if (!enableReminder) {
                            selectedReminderTime = null;
                          }
                        });
                      },
                    ),
                    
                    // Reminder Time Picker (only shown if enabled)
                    if (enableReminder)
                      ListTile(
                        leading: const Icon(Icons.access_time, color: AppColors.aiCyan),
                        title: Text(
                          selectedReminderTime != null 
                              ? 'Reminder: ${_formatDateTime(selectedReminderTime!)}' 
                              : 'Select reminder time',
                          style: TextStyle(
                            color: selectedReminderTime != null ? AppColors.aiCyan : null,
                          ),
                        ),
                        onTap: () async {
                          final picked = await _showDateTimePicker();
                          if (picked != null) {
                            setDialogState(() => selectedReminderTime = picked);
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a task title')),
                      );
                      return;
                    }
                    
                    // Validate reminder time if enabled
                    if (enableReminder && selectedReminderTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a reminder time')),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    
                    final appState = Provider.of<AppState>(context, listen: false);
                    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                    
                    final workspaceId = workspaceProvider.currentWorkspace?.id;
                    
                    if (workspaceId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a workspace first')),
                      );
                      return;
                    }
                    
                    TaskPriority priorityEnum;
                    switch (selectedPriority) {
                      case 'high':
                        priorityEnum = TaskPriority.high;
                        break;
                      case 'medium':
                        priorityEnum = TaskPriority.medium;
                        break;
                      default:
                        priorityEnum = TaskPriority.low;
                    }
                    
                    // In _showAddItemDialog() or wherever tasks are created
                    final newTask = Task(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      workspaceId: workspaceId,
                      title: _titleController.text.trim(),
                      subtitle: _subtitleController.text.isEmpty ? "Pending task" : _subtitleController.text,
                      icon: Icons.check_circle_outline_rounded,
                      description: _subtitleController.text,
                      priority: priorityEnum,
                      status: TaskStatus.pending,
                      dueDate: selectedDueDate,
                      reminderAt: enableReminder ? selectedReminderTime : null,
                      reminderEnabled: enableReminder,
                      reminderCompleted: false,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    // This only adds to local state
                    appState.addWorkspaceItem(newTask, workspaceId: workspaceId);

                    // ✅ FIXED: Using _taskApi instead of TaskApi
                    try {
                      final response = await _taskApi.createTask(
                        title: newTask.title,
                        description: newTask.description,
                        priority: newTask.priority,
                        dueDate: newTask.dueDate,
                        reminderAt: newTask.reminderAt,
                        workspaceId: workspaceId,
                      );
                      
                      if (response['success'] == true) {
                        logger.i('✅ Task created on backend: ${response['data']}');
                      } else {
                        logger.e('❌ Task creation failed on backend: ${response['error']}');
                      }
                    } catch (e) {
                      logger.e('❌ Error creating task: $e');
                    }
                    // Schedule notification if reminder is enabled
                    if (enableReminder && selectedReminderTime != null) {
                      await NotificationService().scheduleCustomReminder(
                        title: 'Task Reminder',
                        body: _titleController.text.trim(),
                        scheduledTime: selectedReminderTime!,
                        reminderId: newTask.id,
                      );
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Task added: ${_titleController.text}')),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final currentFilter = workspaceProvider.currentFilter;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

     if (isLoading) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const WorkspaceSelector(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✅ Use the mixin's buildLoadingIndicator
      body: buildLoadingIndicator(message: 'Loading workspace...'),
    );
  }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const WorkspaceSelector(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.aiCyan),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
            tooltip: 'Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.aiCyan),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: _batchDelete,
              child: _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_forever, color: Colors.white),
            )
          : FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              onPressed: _showCreateOptionsDialog,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Filter Chips
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = currentFilter == filter;
                      final displayName = _getDisplayName(filter);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                            workspaceProvider.setFilter(filter);
                          },
                          backgroundColor: Theme.of(context).cardColor,
                          selectedColor: AppColors.aiCyan.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.aiCyan,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.aiCyan : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Workspace Items List
                Expanded(
                  child: const WorkspaceContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayName(String filter) {
    switch (filter) {
      case 'all': return 'All';
      case 'tasks': return 'Tasks';
      case 'notes': return 'Notes';
      case 'files': return 'Files';
      default: return filter;
    }
  }
}

class _UndoItem {
  final int index;
  final String title;
  final String subtitle;
  final bool isMultiple;
  final List<_UndoItem>? items;

  _UndoItem({
    required this.index,
    required this.title,
    required this.subtitle,
  })  : isMultiple = false,
        items = null;

  _UndoItem.multiple(this.items)
      : index = -1,
        title = '',
        subtitle = '',
        isMultiple = true;
}