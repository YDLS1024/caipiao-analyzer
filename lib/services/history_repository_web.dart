import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_record.dart';
import 'history_store.dart';

HistoryStore createHistoryStore() => PrefsHistoryStore();

/// Web 端无 SQLite，用 SharedPreferences 存 JSON 列表
class PrefsHistoryStore implements HistoryStore {
  static const _prefsKey = 'history_records_v1';

  @override
  Future<void> init() async {}

  @override
  Future<int> insert(HistoryRecord record) async {
    final list = await listAll();
    final nextId = list.isEmpty
        ? 1
        : (list.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final saved = HistoryRecord(
      id: nextId,
      createdAt: record.createdAt,
      period: record.period,
      inputTickets: record.inputTickets,
      predictions: record.predictions,
      officialTicket: record.officialTicket,
      note: record.note,
    );
    list.insert(0, saved);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return nextId;
  }

  @override
  Future<List<HistoryRecord>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<HistoryRecord?> getById(int id) async {
    final all = await listAll();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(int id) async {
    final list = await listAll();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
