import 'package:floor/floor.dart';
import '../entities/scanned_qr.dart';

@dao
abstract class ScannedQrDao {
  @Query('SELECT * FROM scanned_qr ORDER BY scan_time DESC')
  Future<List<ScannedQr>> getAllScans();

  @Query(
    'SELECT * FROM scanned_qr WHERE upi_id = :upiId ORDER BY scan_time DESC',
  )
  Future<List<ScannedQr>> getScansByUpi(String upiId);

  @Query('DELETE FROM scanned_qr WHERE upi_id = :upiId')
  Future<void> deleteScansForUpi(String upiId);

  @insert
  Future<int> insertScan(ScannedQr scan);

  @Query(
    'SELECT * FROM scanned_qr GROUP BY upi_id ORDER BY scan_time DESC LIMIT 10',
  )
  Future<List<ScannedQr>> getRecentPayees();

  @delete
  Future<void> deleteScan(ScannedQr scan);

  @delete
  Future<void> deleteScans(List<ScannedQr> scans);

  @Query("UPDATE scanned_qr SET risk_result = 'SAFE' WHERE id = :id")
  Future<void> markAsSafe(int id);
}
