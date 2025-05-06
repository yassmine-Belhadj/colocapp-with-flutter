import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'database_service.dart';

class TaskService {
  final DatabaseService _databaseService = DatabaseService();

  Future<Task> createTask(Task task) async {
    final db = await _databaseService.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<List<Task>> getTasksForGroup(int groupId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'isCompleted ASC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksForUser(int userId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'assignedTo = ?',
      whereArgs: [userId],
      orderBy: 'isCompleted ASC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksAssignedByUser(int userId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'tasks',
      where: 'assignedBy = ?',
      whereArgs: [userId],
      orderBy: 'isCompleted ASC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> updateTask(Task task) async {
    final db = await _databaseService.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await _databaseService.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> toggleTaskCompletion(int taskId, bool isCompleted) async {
    final db = await _databaseService.database;
    await db.update(
      'tasks',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<User>> getUsersForTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return [];

    final db = await _databaseService.database;
    final userIds = [
      ...tasks.map((t) => t.assignedTo),
      ...tasks.map((t) => t.assignedBy)
    ].toSet().toList();

    final maps = await db.query(
      'users',
      where: 'id IN (${List.filled(userIds.length, '?').join(',')})',
      whereArgs: userIds,
    );

    return maps.map((map) => User.fromMap(map)).toList();
  }
}