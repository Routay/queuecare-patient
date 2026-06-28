import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('queuecare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE tickets (
  id $idType,
  ticketNumber $textType,
  department $textType,
  position $integerType,
  estimatedWaitTime $integerType,
  timestamp $textNullableType
)
''');

    await db.execute('''
CREATE TABLE pharmacies (
  id $idType,
  name $textType,
  address $textType,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL
)
''');
  }

  // --- Ticket Operations ---
  Future<void> saveActiveTicket(Map<String, dynamic> ticket) async {
    final db = await instance.database;
    await db.delete('tickets'); // Only keep the active ticket
    await db.insert('tickets', ticket);
  }

  Future<Map<String, dynamic>?> getActiveTicket() async {
    final db = await instance.database;
    final maps = await db.query('tickets', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<void> clearTicket() async {
    final db = await instance.database;
    await db.delete('tickets');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
