import 'package:sqflite/sqflite.dart';
import '../models/group.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'database_service.dart';

class GroupService {
  final DatabaseService _databaseService = DatabaseService();

  Future<Group> createGroup(String name, String description, int adminId) async {
    final db = await _databaseService.database;
    final group = Group(
      name: name,
      description: description,
      adminId: adminId,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('groups', group.toMap());

    // Add admin as member
    await addMemberToGroup(id, adminId);

    // Update user's group
    final authService = AuthService();
    await authService.updateUserGroup(adminId, id);

    return group.copyWith(id: id);
  }

  Future<void> addMemberToGroup(int groupId, int userId) async {
    final db = await _databaseService.database;
    await db.insert(
      'group_members',
      {'groupId': groupId, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Group>> getAllGroups() async {
    final db = await _databaseService.database;
    final maps = await db.query('groups');
    return maps.map((map) => Group.fromMap(map)).toList();
  }

  Future<List<Group>> getGroupsByMemberId(int userId) async {
    final db = await _databaseService.database;
    final maps = await db.rawQuery('''
      SELECT groups.* FROM groups
      JOIN group_members ON groups.id = group_members.groupId
      WHERE group_members.userId = ?
    ''', [userId]);

    return maps.map((map) => Group.fromMap(map)).toList();
  }

  Future<Group?> getGroupById(int id) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Group.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getGroupMembers(int groupId) async {
    final db = await _databaseService.database;
    final maps = await db.rawQuery('''
      SELECT users.* FROM users
      JOIN group_members ON users.id = group_members.userId
      WHERE group_members.groupId = ?
    ''', [groupId]);

    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> updateGroup(Group group) async {
    final db = await _databaseService.database;
    await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeMemberFromGroup(int groupId, int userId) async {
    final db = await _databaseService.database;
    await db.delete(
      'group_members',
      where: 'groupId = ? AND userId = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<List<User>> getNonGroupMembers(int groupId) async {
    final db = await _databaseService.database;
    final maps = await db.rawQuery('''
      SELECT users.* FROM users
      WHERE users.id NOT IN (
        SELECT userId FROM group_members WHERE groupId = ?
      )
    ''', [groupId]);

    return maps.map((map) => User.fromMap(map)).toList();
  }
}

extension GroupExtension on Group {
  Group copyWith({
    int? id,
    String? name,
    String? description,
    int? adminId,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}