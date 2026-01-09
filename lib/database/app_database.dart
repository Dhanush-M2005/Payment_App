import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entities/scanned_qr.dart';
import 'entities/fraud_reference.dart';
import 'entities/user_behavior.dart';
import 'entities/fraud_keywords.dart';
import 'entities/fraud_feedback.dart';
import 'entities/ml_feature.dart';

import 'daos/scanned_qr_dao.dart';
import 'daos/fraud_reference_dao.dart';
import 'daos/user_behavior_dao.dart';
import 'daos/fraud_keywords_dao.dart';
import 'daos/fraud_feedback_dao.dart';
import 'daos/ml_feature_dao.dart';

part 'app_database.g.dart';

@Database(
  version: 5,
  entities: [
    ScannedQr,
    FraudReference,
    UserBehavior,
    FraudKeywords,
    FraudFeedback,
    MlFeature,
  ],
)
abstract class AppDatabase extends FloorDatabase {
  ScannedQrDao get scannedQrDao;
  FraudReferenceDao get fraudReferenceDao;
  UserBehaviorDao get userBehaviorDao;
  FraudKeywordsDao get fraudKeywordsDao;
  FraudFeedbackDao get fraudFeedbackDao;
  MlFeatureDao get mlFeatureDao;
}
