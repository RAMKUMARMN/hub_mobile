import 'package:flutter/material.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  // Mock Data Structure matching Jira-style elements
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': '1',
      'title': 'Sync with backend developer',
      'time': '07:00 - 08:00',
      'status': 'Done',
      'points': 3
    },
    {
      'id': '2',
      'title': 'Design review with product team',
      'time': '09:00 - 10:00',
      'status': 'In Progress',
      'points': 5
    },
    {
      'id': '3',
      'title': 'Fix Tailscale loopback routing issues',
      'time': '11:00 - 12:30',
      'status': 'Todo',
      'points': 8
    },
  ];

  DateTime _selectedDate = DateTime.now();

  // CRUD: Create / Update Modal Sheet
  void _showTaskModal({Map<String, dynamic>? task}) {
    final titleController = TextEditingController(text: task?['title'] ?? '');
    final timeController =
        TextEditingController(text: task?['time'] ?? '10:00 - 11:00');
    String status = task?['status'] ?? 'Todo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
              task == null ? 'Create New Task' : 'Update Task',
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
              controller: timeController,
              decoration: const InputDecoration(
                  labelText: 'Time Interval (e.g. 09:00 - 10:00)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              items: ['Todo', 'In Progress', 'Done']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => status = val ?? 'Todo',
              decoration: const InputDecoration(
                  labelText: 'Sprint Status', border: OutlineInputBorder()),
            ),
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
                onPressed: () {
                  setState(() {
                    if (task == null) {
                      // CREATE
                      _tasks.add({
                        'id': DateTime.now().toString(),
                        'title': titleController.text,
                        'time': timeController.text,
                        'status': status,
                        'points': 2,
                      });
                    } else {
                      // UPDATE
                      task['title'] = titleController.text;
                      task['time'] = timeController.text;
                      task['status'] = status;
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Task',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalTasks = _tasks.length;
    int doneTasks = _tasks.where((t) => t['status'] == 'Done').length;
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
            icon: const Icon(Icons.bar_chart, color: Color(0xFF1976D2)),
            onPressed: () {}, // Future navigation to deep metrics page
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Jira Style Horizontal Calendar
              _buildHorizontalCalendar(),
              const SizedBox(height: 20),

              // 2. Metrics Summary Chart Card
              _buildSprintProgressCard(progressPercent, doneTasks, totalTasks),
              const SizedBox(height: 24),

              // Section Header
              const Text(
                'Today\'s Schedule',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333)),
              ),
              const SizedBox(height: 12),

              // 3. Dynamic Interactive Task List (With inline items)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final item = _tasks[index];
                  return _buildTaskCard(item);
                },
              ),
            ],
          ),
        ),
      ),
      // CREATE Action Trigger
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
              color: Colors.black.withOpacity(0.03),
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
          end: Alignment.bottomRight,
        ),
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
                      ? 'Great work, today\'s plan is complete!'
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
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> item) {
    Color statusColor;
    switch (item['status']) {
      case 'Done':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = const Color(0xFF1976D2);
    }

    return Dismissible(
      key: Key(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (dir) {
        setState(() => _tasks.removeWhere((t) => t['id'] == item['id']));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            item['title'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration:
                  item['status'] == 'Done' ? TextDecoration.lineThrough : null,
              color: item['status'] == 'Done'
                  ? Colors.grey
                  : const Color(0xFF333333),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item['time'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(item['status'],
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_note, color: Color(0xFF1976D2)),
            onPressed: () => _showTaskModal(task: item), // UPDATE TRIGGER
          ),
        ),
      ),
    );
  }
}
