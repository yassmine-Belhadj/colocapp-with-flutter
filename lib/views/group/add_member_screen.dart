import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';

class AddMemberScreen extends StatefulWidget {
  final Group group;

  const AddMemberScreen({super.key, required this.group});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  List<int> _currentMemberIds = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // Get all users
      final allUsers = await AuthService().getAllUsers();

      // Get current group members
      final currentMembers = await GroupService()
          .getGroupMembers(widget.group.id!);
      final currentMemberIds = currentMembers.map((user) => user.id!).toList();

      setState(() {
        _allUsers = allUsers;
        _currentMemberIds = currentMemberIds;
        _filteredUsers = allUsers
            .where((user) => !currentMemberIds.contains(user.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((user) =>
      !_currentMemberIds.contains(user.id) &&
          (user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  Future<void> _addMemberToGroup(User user) async {
    try {
      await GroupService().addMemberToGroup(widget.group.id!, user.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${user.name} to group')),
        );
        setState(() {
          _currentMemberIds.add(user.id!);
          _filteredUsers.removeWhere((u) => u.id == user.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(
              child: Text('No users available to add'),
            )
                : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: user.id == authProvider.user?.id
                      ? const Text('You')
                      : IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addMemberToGroup(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}