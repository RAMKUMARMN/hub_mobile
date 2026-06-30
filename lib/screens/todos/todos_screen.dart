import 'package:flutter/material.dart';
import '../../services/todo_service.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final TodoService _todoService = TodoService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime? _pickedDueDate; // holds the due date+time picked in the modal

  @override
  void initState() {
    super.initState();
    _loadBacklog();
  }

  // Fetch from DB
  Future<void> _loadBacklog() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _todoService.fetchTodos();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network Connection Error: $e')),
      );
    }
  }

  // CREATE / UPDATE Modal Sheet
  void _showTaskModal({Map<String, dynamic>? task}) {
    final titleController = TextEditingController(text: task?['title'] ?? '');
    final descController =
        TextEditingController(text: task?['description'] ?? '');

    // Seed the picked due date if editing an existing task that already has one
    _pickedDueDate = task?['due_date'] != null
        ? DateTime.tryParse(task!['due_date'].toString())?.toLocal()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task == null ? 'Create New Task' : 'Update Task Details',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Task Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                    labelText: 'Description Summary',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              // --- Due date & time picker ---
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _pickedDueDate ?? now,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (date == null) return;

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      _pickedDueDate ?? now.add(const Duration(minutes: 5)),
                    ),
                  );
                  if (time == null) return;

                  setModalState(() {
                    _pickedDueDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Color(0xFF1976D2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedDueDate == null
                              ? 'Set due date & time'
                              : _formatDueDate(_pickedDueDate!),
                          style: TextStyle(
                            color: _pickedDueDate == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontWeight: _pickedDueDate == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_pickedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.grey),
                          onPressed: () {
                            setModalState(() => _pickedDueDate = null);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // --- end due date picker ---

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title is required')),
                      );
                      return;
                    }
                    if (_pickedDueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please pick a due date & time')),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      if (task == null) {
                        await _todoService.createTodo(
                          titleController.text,
                          descController.text,
                          _pickedDueDate!,
                        );
                      } else {
                        // If your backend supports updating title/description/due_date,
                        // call that endpoint here, e.g.:
                        // await _todoService.updateTodo(task['id'].toString(),
                        //     titleController.text, descController.text, _pickedDueDate!);
                      }
                      _loadBacklog();
                    } catch (e) {
                      _loadBacklog();
                    }
                  },
                  child: const Text('Save Task',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper: nice readable format e.g. "30 Jun 2026, 7:35 PM"
  String _formatDueDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return 'Due: ${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = _tasks.length;
    int doneTasks = _tasks.where((t) => t['completed'] == true).length;
    double progressPercent = totalTasks > 0 ? (doneTasks / totalTasks) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Sprint Backlog',
            style: TextStyle(
                color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1976D2)),
            onPressed: _loadBacklog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBacklog,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHorizontalCalendar(),
                      const SizedBox(height: 20),
                      _buildSprintProgressCard(
                          progressPercent, doneTasks, totalTasks),
                      const SizedBox(height: 24),
                      const Text(
                        'Sprint Checklist',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 12),
                      _tasks.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40.0),
                                child: Text('No sprint items in database.',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) =>
                                  _buildTaskCard(_tasks[index]),
                            ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showTaskModal(),
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, idx) {
          DateTime date = DateTime.now().add(Duration(days: idx - 2));
          bool isSelected = date.day == _selectedDate.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF1976D2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ][date.weekday - 1],
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSprintProgressCard(double percent, int done, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sprint Progress Status',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  percent == 1.0
                      ? 'Great work, sprint complete!'
                      : 'Keep pushing forward!',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('$done of $total Tasks Finished',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 75,
                height: 75,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text('${(percent * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item) {
    bool isDone = item['completed'] ?? false;
    Color statusColor = isDone ? Colors.green : const Color(0xFF1976D2);
    String taskId = item['id'].toString();

    return Dismissible(
      key: Key(taskId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (dir) async {
        try {
          await _todoService.deleteTodo(taskId);
        } catch (e) {
          // Soft recovery on network drops
        }
        _loadBacklog();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: IconButton(
            icon: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: statusColor,
            ),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                // Pass the ID and its current completed boolean state
                await _todoService.toggleComplete(taskId, isDone);
              } catch (e) {
                print("Error updating status: $e");
              }
              _loadBacklog();
            },
          ),
          title: Text(
            item['title'] ?? 'Untitled Task',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.grey : const Color(0xFF333333),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              item['description'] ?? 'No description provided.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF1976D2)),
            onPressed: () => _showTaskModal(task: item),
          ),
        ),
      ),
    );
  }
}
