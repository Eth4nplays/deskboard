import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../secrets.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  // Replace these with your actual HA details
  final String _haUrl = 'http://192.168.1.129:8123/api';
  final String _entityId = 'todo.todo'; 
  final String _token = haToken;

  @override
  void initState() {
    super.initState();
    _fetchTasks();

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus && Platform.isLinux) {
        Process.start('onboard', []);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_haUrl/states/$_entityId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // HA returns items inside the 'items' attribute
          _tasks = data['attributes']['items'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask(String task) async {
    if (task.trim().isEmpty) return;
    try {
      await http.post(
        Uri.parse('$_haUrl/services/todo/add_item'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'entity_id': _entityId,
          'item': task.trim(),
        }),
      );
      _controller.clear();
      _fetchTasks();
    } catch (e) {
      debugPrint('Add error: $e');
    }
  }

  Future<void> _toggleComplete(String summary) async {
    try {
      // In HA, updating to 'completed' often removes it from the default view
      await http.post(
        Uri.parse('$_haUrl/services/todo/update_item'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'entity_id': _entityId,
          'item': summary,
          'status': 'completed',
        }),
      );
      _fetchTasks();
    } catch (e) {
      debugPrint('Toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              // Header with Refresh Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "To-Do List",
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        onPressed: _fetchTasks,
                        icon: const Icon(Icons.refresh, size: 20),
                        color: colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                ],
              ),
              const SizedBox(height: 16),

              // Task list
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _tasks.isEmpty
                      ? Center(child: Text("No tasks found.", style: textTheme.bodyMedium))
                      : ListView.separated(
                          itemCount: _tasks.length,
                          separatorBuilder: (_, __) => Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                          itemBuilder: (context, index) {
                            final item = _tasks[index];
                            final bool isCompleted = item['status'] == 'completed';

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['summary'],
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 22,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () => _toggleComplete(item['summary']),
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
                      focusNode: _inputFocusNode,
                      controller: _controller,
                      style: TextStyle(color: colorScheme.onSecondaryContainer),
                      decoration: InputDecoration(
                        hintText: "Add new",
                        filled: true,
                        fillColor: colorScheme.secondaryContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: _addTask,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _addTask(_controller.text),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}