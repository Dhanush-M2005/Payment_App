import 'dart:typed_data';
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

  @ColumnInfo(name: 'hour_of_day')
  final int hour_of_day; // 0-23

  @ColumnInfo(name: 'is_new_receiver')
  final int is_new_receiver; // 0 or 1

  @ColumnInfo(name: 'label')
  final int? label; // Nullable until confirmed fraud or safe

  MlFeature({
    this.id,
    required this.scan_id,
    required this.amount,
    required this.is_in_contacts,
    required this.hour_of_day,
    required this.is_new_receiver,
    this.label,
  });

  /// Returns the features as a Float32List for the ONNX model
  Float32List toFeatureList() {
    return Float32List.fromList([
      amount,
      is_in_contacts.toDouble(),
      hour_of_day.toDouble(),
      is_new_receiver.toDouble(),
    ]);
  }
}
