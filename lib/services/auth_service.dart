import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _databaseService = DatabaseService();

  Future<User?> login(String email, String password) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User> register(String name, String email, String password) async {
    final db = await _databaseService.database;
    final user = User(
      name: name,
      email: email,
      password: password,
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<List<User>> getAllUsers() async {
    final db = await DatabaseService().database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> updateUserGroup(int userId, int? groupId) async {
    final db = await _databaseService.database;
    await db.update(
      'users',
      {'groupId': groupId},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}

extension UserExtension on User {
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    int? groupId,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      groupId: groupId ?? this.groupId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}