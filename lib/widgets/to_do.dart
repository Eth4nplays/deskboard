import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final TextEditingController _controller = TextEditingController();
  List<String> _tasks = [];
  Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('tasks') ?? [];
      _completed =
          (prefs.getStringList('completed') ?? [])
              .map((e) => int.parse(e))
              .toSet();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', _tasks);
    await prefs.setStringList(
      'completed',
      _completed.map((e) => e.toString()).toList(),
    );
  }

  void _addTask(String task) {
    if (task.trim().isEmpty) return;
    setState(() => _tasks.add(task.trim()));
    _controller.clear();
    _saveTasks();
  }

  void _toggleComplete(int index) {
    setState(() {
      _tasks.removeAt(index);
      _completed =
          _completed
              .where((i) => i != index)
              .map((i) => i > index ? i - 1 : i)
              .toSet();
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate remaining height for the task list dynamically
        final availableHeight = constraints.maxHeight - 140;
        // 140 accounts for padding, header, input row, and spacing

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    "To-Do List",
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task list (scrollable)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          _tasks.isEmpty
                              ? Center(
                                child: Text(
                                  "No tasks yet.",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _tasks.length,
                                separatorBuilder:
                                    (_, __) =>
                                        Divider(color: colorScheme.outline),
                                itemBuilder: (context, index) {
                                  final task = _tasks[index];
                                  final completed = _completed.contains(index);
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color:
                                                colorScheme
                                                    .onSecondaryContainer,
                                            decoration:
                                                completed
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        padding: EdgeInsets.zero,
                                        iconSize: 20,
                                        icon: Icon(
                                          Icons.check,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                        onPressed: () => _toggleComplete(index),
                                      ),
                                    ],
                                  );
                                },
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color:
                                colorScheme
                                    .onSecondaryContainer, // text you type will be this color
                          ),
                          decoration: InputDecoration(
                            hintText: "Add new",
                            hintStyle: TextStyle(
                              color:
                                  colorScheme
                                      .onSurfaceVariant, // hint text color
                            ),
                            filled: true,
                            fillColor: colorScheme.secondaryContainer,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: _addTask,
                        ),
                      ),

                      const SizedBox(width: 8),
                      SizedBox(
                        width: 35, // desired width
                        height: 35, // desired height
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding:
                                EdgeInsets
                                    .zero, // remove internal padding if needed
                          ),
                          onPressed: () => _addTask(_controller.text),
                          child: const Text('+'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
