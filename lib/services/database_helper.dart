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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        population INTEGER
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          country TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          population INTEGER
        )
      ''');
      print('Upgraded database to version $newVersion: ensured cities table exists');
    }
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

  Future<void> saveLastCity(CitySuggestion city) async {
    final db = await database;
    await db.delete('cities'); // Clear previous city
    await db.insert('cities', {
      'name': city.name,
      'country': city.country,
      'latitude': city.lat,
      'longitude': city.lon,
      'population': city.population,
    });
    print('Saved city: ${city.name}, ${city.country}');
  }

  Future<CitySuggestion?> getLastCity() async {
    final db = await database;
    final maps = await db.query('cities', limit: 1);
    if (maps.isNotEmpty) {
      final city = CitySuggestion.fromJson(maps.first);
      print('Retrieved city: ${city.name}, ${city.country}');
      return city;
    }
    print('No city found in database');
    return null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}