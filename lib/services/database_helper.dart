import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:valid_weather/models/city_suggestion.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('weather.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveUnitPreference(String unit) async {
    final db = await database;
    await db.delete('settings'); // Clear previous setting
    await db.insert('settings', {'unit': unit});
    print('Saved unit preference: $unit');
  }

  Future<String> getUnitPreference() async {
    final db = await database;
    final maps = await db.query('settings', limit: 1);
    if (maps.isNotEmpty) {
      final unit = maps.first['unit'] as String;
      print('Retrieved unit preference: $unit');
      return unit;
    }
    print('No unit preference found, defaulting to metric');
    return 'metric';
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}