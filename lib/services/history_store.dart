import '../models/history_record.dart';

abstract class HistoryStore {
  Future<void> init();
  Future<int> insert(HistoryRecord record);
  Future<List<HistoryRecord>> listAll();
  Future<HistoryRecord?> getById(int id);
  Future<void> delete(int id);
  Future<void> clear();
}
