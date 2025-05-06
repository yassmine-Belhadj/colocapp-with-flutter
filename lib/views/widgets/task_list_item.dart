import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/user.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final User? assignedTo;
  final User? assignedBy;
  final bool isAdmin;
  final Function()? onToggle;
  final Function()? onEdit;
  final Function()? onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    this.assignedTo,
    this.assignedBy,
    this.isAdmin = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: onToggle != null ? (_) => onToggle!() : null,
        ),
        title: Text(
          task.description,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignedTo != null)
              Text('Assigned to: ${assignedTo!.name}'),
            if (assignedBy != null && isAdmin)
              Text('Assigned by: ${assignedBy!.name}'),
            if (task.completedAt != null)
              Text('Completed: ${task.completedAt!.toString()}'),
          ],
        ),
        trailing: isAdmin
            ? PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit' && onEdit != null) {
              onEdit!();
            } else if (value == 'delete' && onDelete != null) {
              onDelete!();
            }
          },
        )
            : null,
      ),
    );
  }
}