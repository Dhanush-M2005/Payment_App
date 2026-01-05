import 'package:floor/floor.dart';
import '../entities/fraud_reference.dart';

@dao
abstract class FraudReferenceDao {
  @Query('SELECT * FROM fraud_reference WHERE upi_hash = :upiHash')
  Future<FraudReference?> findByUpiHash(String upiHash);

  @insert
  Future<void> insertFraudReference(FraudReference reference);

  @Query('DELETE FROM fraud_reference')
  Future<void> deleteAll();
}
