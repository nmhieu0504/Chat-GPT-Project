// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, camel_case_types

import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import './message.dart';

class DB_Ultils {
  static final DB_Ultils _instance = DB_Ultils._init();
  DB_Ultils._init();

  static late Database _database;

  Future<Database> get database async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'message_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages_table(message TEXT, date TEXT, isUser INTEGER)',
        );
      },
      version: 1,
    );
    return _database;
  }

  static Future<void> insertMessage(Message message) async {
    final db = await _instance.database;

    await db.insert(
      'messages_table',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Message>> loadAll() async {
    final db = await _instance.database;

    final List<Map<String, dynamic>> maps = await db.query('messages_table');

    return List.generate(maps.length, (i) {
      bool checkUser;
      if (maps[i]['isUser'] == 1)
        checkUser = true;
      else
        checkUser = false;

      return Message(
        message: maps[i]['message'],
        date: DateTime.parse(maps[i]['date']),
        isUser: checkUser,
      );
    });
  }

  static Future<void> deleteAll() async {
    final db = await _instance.database;

    await db.delete(
      'messages_table',
      where: null,
    );
  }
}

// void main() async {
//   final database = openDatabase(
//     join(await getDatabasesPath(), 'message_database.db'),
//     onCreate: (db, version) {
//       return db.execute(
//         'CREATE TABLE messages_table(message TEXT, date TEXT, isUser INTEGER)',
//       );
//     },
//     version: 1,
//   );

//   var fido = Message(
//     message: 'SWE',
//     date: DateTime.now(),
//     isUser: false,
//   );

//   await insertMessage(fido);
//   print(await loadAll());
//   print(await loadAll());
// }
