import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;

import '../models/history_record.dart';
import 'history_store.dart';

HistoryStore createHistoryStore() => SqliteHistoryStore();

class SqliteHistoryStore implements HistoryStore {
  Database? _db;
  static const _table = 'analysis_history';

  @override
  Future<void> init() async {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'caipiao_analyzer.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,
  period TEXT NOT NULL,
  payload TEXT NOT NULL
)
''');
        await db.execute(
          'CREATE INDEX idx_history_period ON $_table(period)',
        );
        await db.execute(
          'CREATE INDEX idx_history_created ON $_table(created_at)',
        );
      },
    );
  }

  @override
  Future<int> insert(HistoryRecord record) async {
    final db = _db;
    if (db == null) throw StateError('SQLite 未初始化');
    return db.insert(_table, {
      'created_at': record.createdAt.toIso8601String(),
      'period': record.period,
      'payload': record.encodePayload(),
    });
  }

  @override
  Future<List<HistoryRecord>> listAll() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(
      _table,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<HistoryRecord?> getById(int id) async {
    final db = _db;
    if (db == null) return null;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<void> delete(int id) async {
    final db = _db;
    if (db == null) return;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async {
    final db = _db;
    if (db == null) return;
    await db.delete(_table);
  }

  HistoryRecord _fromRow(Map<String, Object?> row) {
    final payload =
        jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return HistoryRecord.fromJson({
      ...payload,
      'id': row['id'] as int,
    });
  }
}
