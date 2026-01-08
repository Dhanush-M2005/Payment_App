import 'package:floor/floor.dart';
import '../entities/ml_feature.dart';

@dao
abstract class MlFeatureDao {
  @Query('SELECT * FROM ml_features ORDER BY id DESC')
  Future<List<MlFeature>> getAllMlFeatures();

  @Query('SELECT * FROM ml_features WHERE scan_id = :scanId')
  Future<MlFeature?> findByScanId(int scanId);

  @insert
  Future<void> insertMlFeature(MlFeature feature);

  @Query('SELECT COUNT(*) FROM ml_features')
  Future<int?> getFeatureCount();

  @Query(
    'SELECT COUNT(*) FROM ml_features JOIN scanned_qr ON ml_features.scan_id = scanned_qr.id WHERE scanned_qr.upi_id = :upiId',
  )
  Future<int?> getCountByUpiId(String upiId);

  @Query(
    'SELECT COUNT(*) FROM ml_features JOIN scanned_qr ON ml_features.scan_id = scanned_qr.id WHERE scanned_qr.scan_time > :timestamp',
  )
  Future<int?> getRecentScanCount(int timestamp);
}
