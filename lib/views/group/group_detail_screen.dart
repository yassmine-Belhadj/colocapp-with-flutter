import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/task_service.dart';
import '../task/admin_tasks_screen.dart';
import '../task/user_tasks_screen.dart';
import '../widgets/task_dialog.dart';
import 'add_member_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final group = groupProvider.currentGroup!;
    final isAdmin = group.adminId == authProvider.user?.id;
    final currentUserId = authProvider.user?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGroupScreen(group: group),
                    ),
                  );
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people)),
              Tab(icon: Icon(Icons.task)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Members Tab
            RefreshIndicator(
              onRefresh: () async {
                groupProvider.setCurrentGroup(group);
              },
              child: _buildMembersList(context, groupProvider, group, isAdmin, currentUserId),
            ),
            // Tasks Tab
            isAdmin
                ? const AdminTasksScreen()
                : const UserTasksScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(
      BuildContext context,
      GroupProvider groupProvider,
      Group group,
      bool isAdmin,
      int? currentUserId,
      ) {
    return FutureBuilder<List<User>>(
      future: GroupService().getGroupMembers(group.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final members = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(group.description),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (isAdmin)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMemberScreen(group: group),
                          ),
                        );
                      },
                      child: const Text('Add Members'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isCurrentUser = member.id == currentUserId;
                  final isGroupAdmin = member.id == group.adminId;

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    trailing: isGroupAdmin
                        ? const Text('Admin')
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.task),
                            onPressed: () => _showCreateTaskForMemberDialog(
                              context,
                              group,
                              member,
                            ),
                          ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _removeMember(
                              context,
                              groupProvider,
                              group,
                              member,
                            ),
                          ),
                        if (isCurrentUser && !isGroupAdmin)
                          TextButton(
                            onPressed: () => _leaveGroup(
                              context,
                              groupProvider,
                              group,
                              member,
                            ),
                            child: const Text(
                              'Leave',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateTaskForMemberDialog(
      BuildContext context,
      Group group,
      User member,
      ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        initialAssignedTo: member,
        availableMembers: [member],
        title: 'Create Task for ${member.name}',
      ),
    );

    if (result != null) {
      final task = Task(
        description: result['description'] as String,
        groupId: group.id!,
        assignedTo: member.id!,
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

  Future<void> _removeMember(
      BuildContext context,
      GroupProvider groupProvider,
      Group group,
      User member,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupService().removeMemberFromGroup(group.id!, member.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member.name} removed')),
          );
          groupProvider.setCurrentGroup(group);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  Future<void> _leaveGroup(
      BuildContext context,
      GroupProvider groupProvider,
      Group group,
      User member,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupService().removeMemberFromGroup(group.id!, member.id!);
        final authService = AuthService();
        await authService.updateUserGroup(member.id!, null);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You left the group')),
          );
          Navigator.pop(context); // Go back to group list
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave group: $e')),
          );
        }
      }
    }
  }
}