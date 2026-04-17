import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    return (select(syncQueue)
      ..where((t) => t.synced.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit))
        .get();
  }

  Future<int> addToQueue(SyncQueueCompanion item) async {
    return into(syncQueue).insert(item);
  }

  Future<bool> markAsSynced(int id) async {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(synced: Value(true)),
    );
  }

  Future<bool> deleteFromQueue(int id) async {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearSyncedItems() async {
    await (delete(syncQueue)..where((t) => t.synced.equals(true))).go();
  }

  Future<int> getPendingCount() async {
    final pending = await (select(syncQueue)..where((t) => t.synced.equals(false))).get();
    return pending.length;
  }

  Stream<List<SyncQueueItem>> watchPendingItems() {
    return (select(syncQueue)
      ..where((t) => t.synced.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }
}
