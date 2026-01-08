import 'package:floor/floor.dart';
import 'scanned_qr.dart';

@Entity(
  tableName: 'ml_features',
  foreignKeys: [
    ForeignKey(
      childColumns: ['scan_id'],
      parentColumns: ['id'],
      entity: ScannedQr,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
)
class MlFeature {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'scan_id')
  final int scan_id;

  // ML Features in the requested order
  @ColumnInfo(name: 'amount')
  final double amount;

  @ColumnInfo(name: 'is_in_contacts')
  final int is_in_contacts; // 0 or 1

  @ColumnInfo(name: 'qr_type')
  final int qr_type; // 0=P2P, 1=Merchant

  @ColumnInfo(name: 'hour_of_day')
  final int hour_of_day; // 0-23

  @ColumnInfo(name: 'is_new_receiver')
  final int is_new_receiver; // 0 or 1

  @ColumnInfo(name: 'scan_frequency')
  final int scan_frequency;

  @ColumnInfo(name: 'label')
  final int? label; // Nullable until confirmed fraud or safe

  MlFeature({
    this.id,
    required this.scan_id,
    required this.amount,
    required this.is_in_contacts,
    required this.qr_type,
    required this.hour_of_day,
    required this.is_new_receiver,
    required this.scan_frequency,
    this.label,
  });

  /// Returns the features as a list in the exact order required by the ML model
  List<double> toFeatureList() {
    return [
      amount,
      is_in_contacts.toDouble(),
      qr_type.toDouble(),
      hour_of_day.toDouble(),
      is_new_receiver.toDouble(),
      scan_frequency.toDouble(),
    ];
  }
}
