import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/group_service.dart';
import '../services/task_service.dart';
import 'auth/login_screen.dart';
import 'group/create_group_screen.dart';
import 'group/group_detail_screen.dart';
import 'group/group_list_screen.dart';
import 'widgets/task_dialog.dart';
import 'widgets/task_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Task> _tasks = [];
  List<User> _groupMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await groupProvider.loadGroups();
    if (authProvider.user?.groupId != null) {
      await _loadGroupMembers(authProvider.user!.groupId!);
    }
    await _loadTasks();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadGroupMembers(int groupId) async {
    final groupService = GroupService();
    final members = await groupService.getGroupMembers(groupId);
    setState(() {
      _groupMembers = members;
    });
  }

  Future<void> _loadTasks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || user.id == null) return;

    final taskService = TaskService();
    final tasks = user.isAdmin
        ? await taskService.getTasksAssignedByUser(user.id!)
        : await taskService.getTasksForUser(user.id!);

    setState(() {
      _tasks = tasks;
    });
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    if (task.id == null) return;
    final taskService = TaskService();
    await taskService.toggleTaskCompletion(task.id!, !task.isCompleted);
    await _loadTasks();
  }

  Future<void> _createNewTask() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || user.groupId == null || _groupMembers.isEmpty) return;

    final result = await showDialog(
      context: context,
      builder: (context) => TaskDialog(
        title: 'Create New Task',
        availableMembers: _groupMembers,
      ),
    );

    if (result != null && result['description'] != null && result['assignedTo'] != null) {
      final taskService = TaskService();
      final newTask = Task(
        id: null,
        description: result['description'],
        groupId: user.groupId!,
        assignedTo: result['assignedTo'].id!,
        assignedBy: user.id!,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await taskService.createTask(newTask);
      await _loadTasks();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  double _calculateCompletionPercentage(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    int completedCount = tasks.where((task) => task.isCompleted).length;
    return completedCount / tasks.length;
  }

  Widget _buildGroupIcon(Group group) {
    String imagePath;
    switch (group.name.toLowerCase()) {
      case 'office':
        imagePath = 'assets/images/office.png';
        break;
      case 'home':
        imagePath = 'assets/images/home.png';
        break;
      case 'self':
        imagePath = 'assets/images/self.png';
        break;
      default:
        imagePath = 'assets/images/home.png';
    }

    return GestureDetector(
      onTap: () {
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        groupProvider.setCurrentGroup(group);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GroupDetailScreen(),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Image.asset(imagePath, height: 60),
            const SizedBox(height: 8),
            Text(
              group.name,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final user = authProvider.user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    List<Task> userTasks = _tasks.where((task) => task.assignedTo == user?.id).toList();
    List<Task> adminTasks = _tasks.where((task) => task.assignedBy == user?.id).toList();
    bool hasTasks = user?.isAdmin ?? false ? adminTasks.isNotEmpty : userTasks.isNotEmpty;
    double completionPercentage = hasTasks
        ? _calculateCompletionPercentage(user?.isAdmin ?? false ? adminTasks : userTasks)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Master'),
        actions: [
          if (user?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createNewTask,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Guest'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Groups'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupListScreen(),
                  ),
                );
              },
            ),
            if (user != null && user.isAdmin)
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create Group'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                authProvider.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${(completionPercentage * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Groups section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Groups',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: groupProvider.groups.map(_buildGroupIcon).toList(),
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),

          // Tasks section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: hasTasks
                  ? ListView.builder(
                itemCount: user?.isAdmin ?? false ? adminTasks.length : userTasks.length,
                itemBuilder: (context, index) {
                  final task = user?.isAdmin ?? false ? adminTasks[index] : userTasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(task.description),
                      subtitle: Text(
                        'Created: ${task.createdAt.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Checkbox(
                        value: task.isCompleted,
                        onChanged: (bool? value) {
                          if (value != null) {
                            _toggleTaskCompletion(task);
                          }
                        },
                      ),
                    ),
                  );
                },
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/notask.png', height: 100),
                    const SizedBox(height: 16),
                    const Text(
                      'No Tasks!',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}