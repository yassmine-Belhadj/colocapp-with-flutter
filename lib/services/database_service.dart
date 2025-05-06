import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'group_manager.db');
    return await openDatabase(
      path,
      version: 3, // Incremented version to ensure tasks table is created
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createGroupsTable(db);
    await _createGroupMembersTable(db);
    await _createMessagesTable(db);
    await _createTasksTable(db); // Added tasks table creation
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createMessagesTable(db);
    }
    if (oldVersion < 3) {
      await _createTasksTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        groupId INTEGER,
        isAdmin INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createGroupsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        adminId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (adminId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _createGroupMembersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_members(
        groupId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        PRIMARY KEY (groupId, userId),
        FOREIGN KEY (groupId) REFERENCES groups(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMessagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupId INTEGER NOT NULL,
        senderId INTEGER NOT NULL,
        content TEXT NOT NULL,
        sentAt TEXT NOT NULL,
        filePath TEXT,
        isImage INTEGER DEFAULT 0,
        FOREIGN KEY (groupId) REFERENCES groups(id) ON DELETE CASCADE,
        FOREIGN KEY (senderId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        groupId INTEGER NOT NULL,
        assignedTo INTEGER NOT NULL,
        assignedBy INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        FOREIGN KEY (groupId) REFERENCES groups(id) ON DELETE CASCADE,
        FOREIGN KEY (assignedTo) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (assignedBy) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    final db = await database;
    return await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', tableName]);
  }

  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    return result.isNotEmpty;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

}