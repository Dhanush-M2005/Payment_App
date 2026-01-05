import 'package:floor/floor.dart';

@Entity(tableName: 'fraud_reference')
class FraudReference {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'upi_hash')
  final String upiHash;

  @ColumnInfo(name: 'fraud_type')
  final String fraudType;

  @ColumnInfo(name: 'risk_score')
  final int riskScore;

  @ColumnInfo(name: 'last_updated')
  final int lastUpdated;

  FraudReference({
    this.id,
    required this.upiHash,
    required this.fraudType,
    required this.riskScore,
    required this.lastUpdated,
  });
}
