import 'package:flutter/material.dart';
import '../../models/user.dart';

class TaskDialog extends StatefulWidget {
  final String? initialDescription;
  final User? initialAssignedTo;
  final List<User> availableMembers;
  final String title;

  const TaskDialog({
    super.key,
    this.initialDescription,
    this.initialAssignedTo,
    required this.availableMembers,
    required this.title,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _descriptionController;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _selectedUser = widget.initialAssignedTo;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Task Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<User>(
            value: _selectedUser,
            decoration: const InputDecoration(
              labelText: 'Assign to',
              border: OutlineInputBorder(),
            ),
            items: widget.availableMembers.map((user) {
              return DropdownMenuItem<User>(
                value: user,
                child: Text(user.name),
              );
            }).toList(),
            onChanged: (user) {
              setState(() {
                _selectedUser = user;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_descriptionController.text.isNotEmpty && _selectedUser != null) {
              Navigator.pop(context, {
                'description': _descriptionController.text,
                'assignedTo': _selectedUser,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}