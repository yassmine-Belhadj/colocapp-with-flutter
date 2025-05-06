import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/group_service.dart';
import '../../services/task_service.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_list_item.dart';

class AdminTasksScreen extends StatelessWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final group = groupProvider.currentGroup!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks for ${group.name}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context, group),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Task>>(
        future: TaskService().getTasksForGroup(group.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet. Create one by clicking the + button!'),
            );
          }

          return FutureBuilder<List<User>>(
            future: GroupService().getGroupMembers(group.id!),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = membersSnapshot.data ?? [];

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final assignedTo = members.firstWhere(
                        (m) => m.id == task.assignedTo,
                    orElse: () => User(
                      id: -1,
                      name: 'Unknown',
                      email: '',
                      password: '',
                    ),
                  );
                  final assignedBy = members.firstWhere(
                        (m) => m.id == task.assignedBy,
                    orElse: () => User(
                      id: -1,
                      name: 'Unknown',
                      email: '',
                      password: '',
                    ),
                  );

                  return TaskListItem(
                    task: task,
                    assignedTo: assignedTo,
                    assignedBy: assignedBy,
                    isAdmin: true,
                    onToggle: () => _toggleTaskCompletion(context, task),
                    onEdit: () => _showEditTaskDialog(
                      context,
                      group,
                      task,
                      members.where((m) => m.id != group.adminId).toList(),
                    ),
                    onDelete: () => _deleteTask(context, task),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateTaskDialog(BuildContext context, Group group) async {
    final members = await GroupService().getGroupMembers(group.id!);
    final nonAdminMembers = members.where((m) => m.id != group.adminId).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        availableMembers: nonAdminMembers,
        title: 'Create New Task',
      ),
    );

    if (result != null && result['assignedTo'] != null) {
      final assignedTo = result['assignedTo'] as User;
      final task = Task(
        description: result['description'] as String,
        groupId: group.id!,
        assignedTo: assignedTo.id!,
        assignedBy: Provider.of<AuthProvider>(context, listen: false).user!.id!,
        createdAt: DateTime.now(),
      );

      try {
        await TaskService().createTask(task);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create task: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditTaskDialog(
      BuildContext context,
      Group group,
      Task task,
      List<User> availableMembers,
      ) async {
    final assignedToUser = availableMembers.firstWhere(
          (u) => u.id == task.assignedTo,
      orElse: () => User(
        id: -1,
        name: 'Unknown',
        email: '',
        password: '',
      ),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        initialDescription: task.description,
        initialAssignedTo: assignedToUser,
        availableMembers: availableMembers,
        title: 'Edit Task',
      ),
    );

    if (result != null && result['assignedTo'] != null) {
      final assignedTo = result['assignedTo'] as User;
      final updatedTask = task.copyWith(
        description: result['description'] as String,
        assignedTo: assignedTo.id!,
      );

      try {
        await TaskService().updateTask(updatedTask);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update task: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleTaskCompletion(BuildContext context, Task task) async {
    try {
      await TaskService().toggleTaskCompletion(
        task.id!,
        !task.isCompleted,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TaskService().deleteTask(task.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete task: $e')),
          );
        }
      }
    }
  }
}