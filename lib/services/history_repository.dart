import '../models/history_record.dart';
import 'history_store.dart';
import 'history_repository_io.dart'
    if (dart.library.html) 'history_repository_web.dart' as impl;

/// 历史记录仓库（Android/桌面：SQLite；Web：本地 JSON）
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  final HistoryStore _store = impl.createHistoryStore();

  Future<void> init() => _store.init();

  Future<int> insert(HistoryRecord record) => _store.insert(record);

  Future<List<HistoryRecord>> listAll() => _store.listAll();

  Future<HistoryRecord?> getById(int id) => _store.getById(id);

  Future<void> delete(int id) => _store.delete(id);

  Future<void> clear() => _store.clear();
}
