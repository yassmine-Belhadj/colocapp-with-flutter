import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/task_service.dart';
import '../widgets/task_list_item.dart';

class UserTasksScreen extends StatelessWidget {
  const UserTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: FutureBuilder<List<Task>>(
        future: TaskService().getTasksForUser(currentUser!.id!),
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
              child: Text('You have no tasks assigned.'),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FutureBuilder<List<User>>(
                future: TaskService().getUsersForTasks([task]),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState != ConnectionState.done) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final users = userSnapshot.data ?? [];
                  final assignedBy = users.firstWhere(
                        (u) => u.id == task.assignedBy,
                    orElse: () => User(
                      id: -1,
                      name: 'Unknown',
                      email: '',
                      password: '',
                    ),
                  );

                  return TaskListItem(
                    task: task,
                    assignedBy: assignedBy,
                    onToggle: () => _toggleTaskCompletion(context, task),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
}