import 'package:floor/floor.dart';

@Entity(tableName: 'fraud_keywords')
class FraudKeywords {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'keyword')
  final String keyword;

  @ColumnInfo(name: 'category')
  final String category;

  @ColumnInfo(name: 'risk_weight')
  final int riskWeight;

  FraudKeywords({
    this.id,
    required this.keyword,
    required this.category,
    required this.riskWeight,
  });
}
