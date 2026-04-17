import 'package:drift/drift.dart';
import '../app_database.dart';

part 'feedback_dao.g.dart';

@DriftAccessor(tables: [Feedback])
class FeedbackDao extends DatabaseAccessor<AppDatabase> with _$FeedbackDaoMixin {
  Future<List<FeedbackItem>> getAllFeedback({int limit = 50}) async {
    return (select(feedback)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])..limit(limit)).get();
  }

  Future<FeedbackItem?> getFeedbackById(int id) async {
    return (select(feedback)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertFeedback(FeedbackCompanion feedback) async {
    return into(feedback).insert(feedback);
  }

  Future<bool> deleteFeedback(int id) async {
    return (delete(feedback)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getAverageRating() async {
    final query = select(feedback).join([
      innerJoin(feedback, feedback.stars.isNotNull()),
    ]);
    
    final result = await (select(feedback)..where((t) => t.stars.isNotNull())).get();
    if (result.isEmpty) return 0.0;
    
    final sum = result.fold<int>(0, (prev, curr) => prev + curr.stars);
    return sum / result.length;
  }

  Stream<List<FeedbackItem>> watchAllFeedback({int limit = 50}) {
    return (select(feedback)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])..limit(limit)).watch();
  }
}
