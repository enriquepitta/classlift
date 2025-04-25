import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'my_database.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, quantity INTEGER)",
        );
      },
      version: 1,
    );
  }

  static Future<int> insertItem(Database database, String name, int quantity) async {
    return await database.insert('items', {'name': name, 'quantity': quantity});
  }

  static Future<List<Map<String, dynamic>>> getItems(Database database) async {
    return await database.query('items');
  }
}
