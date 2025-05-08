import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/animation.dart';
import 'dart:math';
import '../models/group.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/group_service.dart';
import '../services/task_service.dart';
import 'auth/ProfileScreen.dart';
import 'auth/login_screen.dart';
import 'group/create_group_screen.dart';
import 'group/group_detail_screen.dart';
import 'group/group_list_screen.dart';
import 'widgets/task_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Task> _tasks = [];
  List<User> _groupMembers = [];
  bool _isLoading = true;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _completionPercentage = 0.0;

  final List<String> _groupIcons = [
    'assets/images/office.png',
    'assets/images/home.png',
    'assets/images/self.png',
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
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

    final newPercentage = _calculateCompletionPercentage(tasks);

    setState(() {
      _tasks = tasks;
      _completionPercentage = newPercentage;
    });

    _progressAnimation = Tween<double>(
      begin: 0,
      end: _completionPercentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    _progressController.forward(from: 0);
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

  String _getRandomGroupIcon() {
    final random = Random();
    return _groupIcons[random.nextInt(_groupIcons.length)];
  }

  Widget _buildGroupCard(Group group) {
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
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Image.asset(_getRandomGroupIcon(), height: 40),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key(task.id?.toString() ?? UniqueKey().toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm"),
              content: const Text("Are you sure you want to delete this task?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        if (task.id != null) {
          final taskService = TaskService();
          await taskService.deleteTask(task.id!);
          await _loadTasks();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            value: task.isCompleted,
            onChanged: (bool? value) {
              if (value != null) {
                _toggleTaskCompletion(task);
              }
            },
          ),
          title: Text(
            task.description,
            style: TextStyle(
              fontSize: 16,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            'Created: ${DateFormat.format(task.createdAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Icon(
            task.isCompleted ? Icons.check_circle : Icons.pending,
            color: task.isCompleted ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _getPercentageColor(_progressAnimation.value),
                      _getPercentageColor(_progressAnimation.value).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getPercentageColor(_progressAnimation.value).withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _getProgressMessage(_completionPercentage),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? iconColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? (isSelected ? Colors.blue : Colors.grey.shade700),
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
      ),
      elevation: 10,
      child: Column(
        children: [
          // Header Section with fixed height
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.95),
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    user?.email ?? 'guest@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Menu Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 0);
                    },
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.group,
                    title: 'Groups',
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
                    _buildDrawerItem(
                      icon: Icons.add_circle_outline,
                      title: 'Create Group',
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
                  _buildDrawerItem(
                    icon: Icons.task,
                    title: 'My Tasks',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 1);
                    },
                    isSelected: _selectedIndex == 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.note,
                    title: 'Notes',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 2);
                    },
                    isSelected: _selectedIndex == 2,
                  ),
                  const Divider(height: 20, thickness: 1, indent: 20, endIndent: 20),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    },
                    isSelected: _selectedIndex == 3,
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      // Add help screen navigation
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: Colors.red,
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
                  const SizedBox(height: 20), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage < 0.3) return Colors.redAccent;
    if (percentage < 0.7) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _getProgressMessage(double percentage) {
    if (percentage == 0) return "Start completing your tasks!";
    if (percentage < 0.3) return "Keep pushing forward!";
    if (percentage < 0.7) return "Great progress so far!";
    if (percentage < 1) return "You're almost done!";
    return "All tasks completed! Amazing work!";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final user = authProvider.user;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Loading your tasks...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Task> userTasks = _tasks.where((task) => task.assignedTo == user?.id).toList();
    List<Task> adminTasks = _tasks.where((task) => task.assignedBy == user?.id).toList();
    bool hasTasks = user?.isAdmin ?? false ? adminTasks.isNotEmpty : userTasks.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Task Master', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (user?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createNewTask,
              tooltip: 'Create Task',
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: _buildProgressIndicator(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Groups',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view group details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: groupProvider.groups.map(_buildGroupCard).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.isAdmin ?? false
                        ? 'Tasks you assigned to others'
                        : 'Tasks assigned to you',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: hasTasks
                  ? Column(
                children: (user?.isAdmin ?? false ? adminTasks : userTasks)
                    .map(_buildTaskItem)
                    .toList(),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/notask.png',
                      height: 120,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Tasks Yet!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.isAdmin ?? false
                          ? 'Create tasks for your team'
                          : 'Tasks assigned to you will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar:
      BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) { // Groups tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupListScreen()),
            );
          } else if (index == 3) { // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
      floatingActionButton: (user?.isAdmin ?? false)
          ? FloatingActionButton(
        onPressed: _createNewTask,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}

class DateFormat {
  static String format(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}