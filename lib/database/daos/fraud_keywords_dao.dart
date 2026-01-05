import 'package:floor/floor.dart';
import '../entities/fraud_keywords.dart';

@dao
abstract class FraudKeywordsDao {
  @Query('SELECT * FROM fraud_keywords')
  Future<List<FraudKeywords>> getAllKeywords();

  @insert
  Future<void> insertKeyword(FraudKeywords keyword);

  @Query('DELETE FROM fraud_keywords')
  Future<void> deleteAll();
}
