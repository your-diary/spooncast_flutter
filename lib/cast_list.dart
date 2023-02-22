import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'cast_downloader.dart';
import 'cast_info.dart';

class CastList extends ChangeNotifier {
  static const String tableName = "casts";

  late final Future<Database> _db;
  List<CastInfo> _l = [];

  CastList(String databasePath) {
    this._openDatabase(databasePath).whenComplete(() async {
      this._l = await this._selectAll();
      notifyListeners();
    });
  }

  List<CastInfo> get l => this._l;

  Future<void> _openDatabase(String databaseFile) async {
    final databasePath = join(await getDatabasesPath(), databaseFile);
    this._db = openDatabase(
      databasePath,
      onCreate: (db, version) {
        return db.execute(
          '''
            CREATE TABLE ${CastList.tableName}(
                id             TEXT PRIMARY KEY,
                author         TEXT,
                title          TEXT,
                voiceURL       TEXT,
                fileExtension  TEXT,
                filePath       TEXT,
                downloadedDate REAL
            )
          ''',
        );
      },
      version: 1,
    );
  }

  Future<void> insert(CastInfo castInfo) async {
    final db = await this._db;
    await db.insert(
      CastList.tableName,
      castInfo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    this._l = await this._selectAll();

    notifyListeners();
  }

  Future<List<CastInfo>> _selectAll() async {
    final db = await this._db;
    final List<Map<String, dynamic>> m = await db.query(CastList.tableName);
    return m.map((m) {
      var castInfo = CastInfo(
        id: m["id"],
        author: m["author"],
        title: m["title"],
        voiceURL: m["voiceURL"],
        fileExtension: m["fileExtension"],
        downloadedDate: DateTime.parse(m["downloadedDate"]),
      );
      castInfo.filePath = m["filePath"];
      return castInfo;
    }).toList();
  }
}
