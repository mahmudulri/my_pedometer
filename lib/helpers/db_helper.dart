import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'walking_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            dayname TEXT,
            start_time TEXT,
            stop_time TEXT,
            total_time TEXT,
            steps INTEGER,
            calories REAL,
            distance REAL,
            weight REAL
          )
        ''');
      },
    );
  }

  Future<void> insertWalkingSession(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('history', data);
  }

  Future<List<Map<String, dynamic>>> getWalkingHistory() async {
    final db = await database;
    return await db.query('history', orderBy: "id DESC");
  }
}
