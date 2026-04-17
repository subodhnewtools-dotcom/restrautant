import 'package:drift/drift.dart';
import '../app_database.dart';

part 'admin_session_dao.g.dart';

@DriftAccessor(tables: [AdminSession])
class AdminSessionDao extends DatabaseAccessor<AppDatabase> with _$AdminSessionDaoMixin {
  Future<AdminSession?> getActiveSession() async {
    final query = select(adminSession);
    final sessions = await query.get();
    return sessions.isNotEmpty ? sessions.first : null;
  }

  Future<void> saveSession(AdminSessionCompanion session) async {
    await into(adminSession).insert(session, mode: InsertMode.insertOrReplace);
  }

  Future<void> clearSession() async {
    await delete(adminSession).go();
  }

  Stream<AdminSession?> watchActiveSession() {
    return (select(adminSession)).watchSingleOrNull();
  }
}
