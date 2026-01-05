import 'package:floor/floor.dart';

@Entity(tableName: 'scanned_qr')
class ScannedQr {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'upi_id')
  final String upiId;

  @ColumnInfo(name: 'payee_name')
  final String payeeName;

  @ColumnInfo(name: 'qr_type')
  final String qrType;

  @ColumnInfo(name: 'scan_time')
  final int scanTime;

  @ColumnInfo(name: 'amount')
  final double? amount;

  @ColumnInfo(name: 'risk_result')
  final String riskResult;

  ScannedQr({
    this.id,
    required this.upiId,
    required this.payeeName,
    required this.qrType,
    required this.scanTime,
    this.amount = 0.0,
    required this.riskResult,
  });
}
