// lib/screens/workspace/workspace_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/workspace_items/task.dart';
import '../../../models/workspace_items/workspace_item.dart';
import '../../../providers/app_state.dart';
import '../../../providers/workspace_provider.dart';
import '../../../services/local/file_service.dart';
import '../../../services/local/note_service.dart';
import '../../../services/local/notification_service.dart';
import '../../../themes/app_colors.dart';
import '../calendar/calendar_screen.dart';
import 'workspace_content.dart';
import 'workspace_selector.dart';
import 'create_workspace_dialog.dart';

class WorkspaceScreen extends StatefulWidget {
  final String? initialWorkspaceId;
  
  const WorkspaceScreen({super.key, this.initialWorkspaceId});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'tasks', 'notes', 'files'];
  
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  bool _isDeleting = false;
  bool _isLoading = true;

  final List<_UndoItem> _undoStack = [];
  
  // Dialog controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  
  late FileService _fileService;
  late NoteService _noteService;

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
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    await workspaceProvider.loadWorkspaces();
    
    if (widget.initialWorkspaceId != null) {
      workspaceProvider.selectWorkspaceById(widget.initialWorkspaceId!);
    }
    
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);
      final currentWorkspace = workspaceProvider.currentWorkspace;
      
      // Add test task to verify display
      final testTask = Task(
        id: 'test_1',
        workspaceId: currentWorkspace?.id ?? 'general',
        title: 'Test Task - Click to complete',
        subtitle: 'This is a test task',
        icon: Icons.task_alt,
        description: 'If you see this, the display is working!',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        dueDate: null,
        reminderAt: null,
        reminderEnabled: false,
        reminderCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      appState.addWorkspaceItem(testTask);
      
      if (currentWorkspace != null) {
        // Clear existing items for this workspace to avoid duplicates
        final itemsToRemove = appState.workspaceItems.where((item) => 
          item.workspaceId == currentWorkspace.id
        ).toList();
        
        for (var item in itemsToRemove) {
          final index = appState.workspaceItems.indexOf(item);
          if (index != -1) {
            appState.removeWorkspaceItem(index);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadAllDataFromBackend();
    } catch (e) {
      debugPrint('Refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refreshed!'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIndices.isEmpty) return;
    
    setState(() => _isDeleting = true);
    
    final appState = Provider.of<AppState>(context, listen: false);
    final itemsToDelete = _selectedIndices.map((i) {
      final item = appState.workspaceItems[i];
      return _UndoItem(
        index: i,
        title: item.title,
        subtitle: item.subtitle,
      );
    }).toList();
    
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (var index in sortedIndices) {
      appState.removeWorkspaceItem(index);
    }
    
    _undoStack.add(_UndoItem.multiple(itemsToDelete));
    
    setState(() => _isDeleting = false);
    _exitSelectionMode();
    
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

  void _undoLastDelete() async {
    if (_undoStack.isEmpty) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final undoItem = _undoStack.removeLast();
    
    if (undoItem.isMultiple) {
      for (var item in undoItem.items!) {
        final restoredItem = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          workspaceId: appState.currentWorkspace?.id ?? 'general',
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
        appState.addWorkspaceItem(restoredItem);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restored items'), duration: Duration(seconds: 2)),
      );
    } else {
      final restoredItem = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workspaceId: appState.currentWorkspace?.id ?? 'general',
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
      appState.addWorkspaceItem(restoredItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored: ${undoItem.title}'), duration: const Duration(seconds: 2)),
      );
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

  Future<void> _showCreateWorkspaceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const CreateWorkspaceDialog(),
    );
    await _initializeWorkspace();
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

  // lib/screens/workspace/workspace_screen.dart

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
                          DropdownMenuItem(value: 'critical', child: Text('🟣 Critical Priority')),
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
                  
                  // ✅ FIXED: Get workspace ID and validate it exists
                  final workspaceId = workspaceProvider.currentWorkspace?.id;
                  
                  if (workspaceId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a workspace first')),
                    );
                    return;
                  }
                  
                  TaskPriority priorityEnum;
                  switch (selectedPriority) {
                    case 'critical':
                      priorityEnum = TaskPriority.critical;
                      break;
                    case 'high':
                      priorityEnum = TaskPriority.high;
                      break;
                    case 'medium':
                      priorityEnum = TaskPriority.medium;
                      break;
                    default:
                      priorityEnum = TaskPriority.low;
                  }
                  
                  final newTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    workspaceId: workspaceId,  // ✅ Uses actual workspace ID
                    title: _titleController.text.trim(),
                    subtitle: _subtitleController.text.isEmpty 
                        ? "Pending task" 
                        : _subtitleController.text,
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
                  
                  appState.addWorkspaceItem(newTask);
                  
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

  void _editItem(int index, WorkspaceItem item) {
    // Handled by WorkspaceContent
  }

  void _deleteItem(int index, WorkspaceItem item) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    _undoStack.add(_UndoItem(
      index: index,
      title: item.title,
      subtitle: item.subtitle,
    ));
    
    appState.removeWorkspaceItem(index);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted: ${item.title}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _undoLastDelete(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final workspaceProvider = Provider.of<WorkspaceProvider>(context);
    final currentFilter = workspaceProvider.currentFilter;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

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
        onRefresh: _loadData,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Filter Chips (removed 'reminders')
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

  Widget _buildShimmerEffect() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor = isDark 
        ? Colors.grey.shade800.withValues(alpha: 0.5)
        : Colors.grey.shade300.withValues(alpha: 0.5);
    
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: shimmerColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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