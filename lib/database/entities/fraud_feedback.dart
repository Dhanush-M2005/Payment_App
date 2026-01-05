import 'package:floor/floor.dart';

@Entity(tableName: 'fraud_feedback')
class FraudFeedback {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'upi_hash')
  final String upiHash;

  @ColumnInfo(name: 'was_fraud')
  final int wasFraud;

  @ColumnInfo(name: 'user_action')
  final String userAction;

  @ColumnInfo(name: 'reported_time')
  final int reportedTime;

  FraudFeedback({
    this.id,
    required this.upiHash,
    required this.wasFraud,
    required this.userAction,
    required this.reportedTime,
  });
}
