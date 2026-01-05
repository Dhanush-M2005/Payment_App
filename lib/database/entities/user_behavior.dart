import 'package:floor/floor.dart';

@Entity(tableName: 'user_behavior')
class UserBehavior {
  @PrimaryKey(autoGenerate: false)
  final int id;

  @ColumnInfo(name: 'avg_amount')
  final double avgAmount;

  @ColumnInfo(name: 'max_amount')
  final double maxAmount;

  @ColumnInfo(name: 'txn_count')
  final int txnCount;

  @ColumnInfo(name: 'last_txn_time')
  final int lastTxnTime;

  UserBehavior({
    this.id = 1,
    required this.avgAmount,
    required this.maxAmount,
    required this.txnCount,
    required this.lastTxnTime,
  });
}
