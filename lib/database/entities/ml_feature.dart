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
  final int scanId;

  // ML Features in the requested order
  @ColumnInfo(name: 'amount')
  final double amount;

  @ColumnInfo(name: 'is_in_contacts')
  final int isInContacts; // 0 or 1

  @ColumnInfo(name: 'hour_of_day')
  final int hourOfDay; // 0-23

  @ColumnInfo(name: 'is_new_receiver')
  final int isNewReceiver; // 0 or 1

  @ColumnInfo(name: 'label')
  final int? label; // Nullable until confirmed fraud or safe

  MlFeature({
    this.id,
    required this.scanId,
    required this.amount,
    required this.isInContacts,
    required this.hourOfDay,
    required this.isNewReceiver,
    this.label,
  });

  /// Returns the features as a Float32List for the ONNX model
  Float32List toFeatureList() {
    return Float32List.fromList([
      amount,
      isInContacts.toDouble(),
      hourOfDay.toDouble(),
      isNewReceiver.toDouble(),
    ]);
  }
}
