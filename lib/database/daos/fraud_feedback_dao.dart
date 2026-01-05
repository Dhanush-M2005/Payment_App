import 'package:floor/floor.dart';
import '../entities/fraud_feedback.dart';

@dao
abstract class FraudFeedbackDao {
  @Query('SELECT * FROM fraud_feedback ORDER BY reported_time DESC')
  Future<List<FraudFeedback>> getAllFeedback();

  @insert
  Future<void> insertFeedback(FraudFeedback feedback);
}
