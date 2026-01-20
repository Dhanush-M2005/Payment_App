// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ScannedQrDao? _scannedQrDaoInstance;

  FraudReferenceDao? _fraudReferenceDaoInstance;

  UserBehaviorDao? _userBehaviorDaoInstance;

  FraudKeywordsDao? _fraudKeywordsDaoInstance;

  FraudFeedbackDao? _fraudFeedbackDaoInstance;

  MlFeatureDao? _mlFeatureDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 5,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `scanned_qr` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `upi_id` TEXT NOT NULL, `payee_name` TEXT NOT NULL, `qr_type` TEXT NOT NULL, `scan_time` INTEGER NOT NULL, `amount` REAL, `risk_result` TEXT NOT NULL, `is_in_contacts` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fraud_reference` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `upi_hash` TEXT NOT NULL, `fraud_type` TEXT NOT NULL, `risk_score` INTEGER NOT NULL, `last_updated` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `user_behavior` (`id` INTEGER NOT NULL, `avg_amount` REAL NOT NULL, `max_amount` REAL NOT NULL, `txn_count` INTEGER NOT NULL, `last_txn_time` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fraud_keywords` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `keyword` TEXT NOT NULL, `category` TEXT NOT NULL, `risk_weight` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `fraud_feedback` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `upi_hash` TEXT NOT NULL, `was_fraud` INTEGER NOT NULL, `user_action` TEXT NOT NULL, `reported_time` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ml_features` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `scan_id` INTEGER NOT NULL, `amount` REAL NOT NULL, `is_in_contacts` INTEGER NOT NULL, `hour_of_day` INTEGER NOT NULL, `is_new_receiver` INTEGER NOT NULL, `label` INTEGER, FOREIGN KEY (`scan_id`) REFERENCES `scanned_qr` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ScannedQrDao get scannedQrDao {
    return _scannedQrDaoInstance ??= _$ScannedQrDao(database, changeListener);
  }

  @override
  FraudReferenceDao get fraudReferenceDao {
    return _fraudReferenceDaoInstance ??=
        _$FraudReferenceDao(database, changeListener);
  }

  @override
  UserBehaviorDao get userBehaviorDao {
    return _userBehaviorDaoInstance ??=
        _$UserBehaviorDao(database, changeListener);
  }

  @override
  FraudKeywordsDao get fraudKeywordsDao {
    return _fraudKeywordsDaoInstance ??=
        _$FraudKeywordsDao(database, changeListener);
  }

  @override
  FraudFeedbackDao get fraudFeedbackDao {
    return _fraudFeedbackDaoInstance ??=
        _$FraudFeedbackDao(database, changeListener);
  }

  @override
  MlFeatureDao get mlFeatureDao {
    return _mlFeatureDaoInstance ??= _$MlFeatureDao(database, changeListener);
  }
}

class _$ScannedQrDao extends ScannedQrDao {
  _$ScannedQrDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _scannedQrInsertionAdapter = InsertionAdapter(
            database,
            'scanned_qr',
            (ScannedQr item) => <String, Object?>{
                  'id': item.id,
                  'upi_id': item.upiId,
                  'payee_name': item.payeeName,
                  'qr_type': item.qrType,
                  'scan_time': item.scanTime,
                  'amount': item.amount,
                  'risk_result': item.riskResult,
                  'is_in_contacts': item.isInContacts ? 1 : 0
                }),
        _scannedQrDeletionAdapter = DeletionAdapter(
            database,
            'scanned_qr',
            ['id'],
            (ScannedQr item) => <String, Object?>{
                  'id': item.id,
                  'upi_id': item.upiId,
                  'payee_name': item.payeeName,
                  'qr_type': item.qrType,
                  'scan_time': item.scanTime,
                  'amount': item.amount,
                  'risk_result': item.riskResult,
                  'is_in_contacts': item.isInContacts ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScannedQr> _scannedQrInsertionAdapter;

  final DeletionAdapter<ScannedQr> _scannedQrDeletionAdapter;

  @override
  Future<List<ScannedQr>> getAllScans() async {
    return _queryAdapter.queryList(
        'SELECT * FROM scanned_qr ORDER BY scan_time DESC',
        mapper: (Map<String, Object?> row) => ScannedQr(
            id: row['id'] as int?,
            upiId: row['upi_id'] as String,
            payeeName: row['payee_name'] as String,
            qrType: row['qr_type'] as String,
            scanTime: row['scan_time'] as int,
            amount: row['amount'] as double?,
            riskResult: row['risk_result'] as String,
            isInContacts: (row['is_in_contacts'] as int) != 0));
  }

  @override
  Future<List<ScannedQr>> getScansByUpi(String upiId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM scanned_qr WHERE upi_id = ?1 ORDER BY scan_time DESC',
        mapper: (Map<String, Object?> row) => ScannedQr(
            id: row['id'] as int?,
            upiId: row['upi_id'] as String,
            payeeName: row['payee_name'] as String,
            qrType: row['qr_type'] as String,
            scanTime: row['scan_time'] as int,
            amount: row['amount'] as double?,
            riskResult: row['risk_result'] as String,
            isInContacts: (row['is_in_contacts'] as int) != 0),
        arguments: [upiId]);
  }

  @override
  Future<void> deleteScansForUpi(String upiId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM scanned_qr WHERE upi_id = ?1',
        arguments: [upiId]);
  }

  @override
  Future<List<ScannedQr>> getRecentPayees() async {
    return _queryAdapter.queryList(
        'SELECT * FROM scanned_qr GROUP BY upi_id ORDER BY scan_time DESC LIMIT 10',
        mapper: (Map<String, Object?> row) => ScannedQr(
            id: row['id'] as int?,
            upiId: row['upi_id'] as String,
            payeeName: row['payee_name'] as String,
            qrType: row['qr_type'] as String,
            scanTime: row['scan_time'] as int,
            amount: row['amount'] as double?,
            riskResult: row['risk_result'] as String,
            isInContacts: (row['is_in_contacts'] as int) != 0));
  }

  @override
  Future<void> markAsSafe(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE scanned_qr SET risk_result = \'SAFE\' WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<int> insertScan(ScannedQr scan) {
    return _scannedQrInsertionAdapter.insertAndReturnId(
        scan, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteScan(ScannedQr scan) async {
    await _scannedQrDeletionAdapter.delete(scan);
  }

  @override
  Future<void> deleteScans(List<ScannedQr> scans) async {
    await _scannedQrDeletionAdapter.deleteList(scans);
  }
}

class _$FraudReferenceDao extends FraudReferenceDao {
  _$FraudReferenceDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _fraudReferenceInsertionAdapter = InsertionAdapter(
            database,
            'fraud_reference',
            (FraudReference item) => <String, Object?>{
                  'id': item.id,
                  'upi_hash': item.upiHash,
                  'fraud_type': item.fraudType,
                  'risk_score': item.riskScore,
                  'last_updated': item.lastUpdated
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FraudReference> _fraudReferenceInsertionAdapter;

  @override
  Future<FraudReference?> findByUpiHash(String upiHash) async {
    return _queryAdapter.query(
        'SELECT * FROM fraud_reference WHERE upi_hash = ?1',
        mapper: (Map<String, Object?> row) => FraudReference(
            id: row['id'] as int?,
            upiHash: row['upi_hash'] as String,
            fraudType: row['fraud_type'] as String,
            riskScore: row['risk_score'] as int,
            lastUpdated: row['last_updated'] as int),
        arguments: [upiHash]);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM fraud_reference');
  }

  @override
  Future<void> insertFraudReference(FraudReference reference) async {
    await _fraudReferenceInsertionAdapter.insert(
        reference, OnConflictStrategy.abort);
  }
}

class _$UserBehaviorDao extends UserBehaviorDao {
  _$UserBehaviorDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userBehaviorInsertionAdapter = InsertionAdapter(
            database,
            'user_behavior',
            (UserBehavior item) => <String, Object?>{
                  'id': item.id,
                  'avg_amount': item.avgAmount,
                  'max_amount': item.maxAmount,
                  'txn_count': item.txnCount,
                  'last_txn_time': item.lastTxnTime
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<UserBehavior> _userBehaviorInsertionAdapter;

  @override
  Future<UserBehavior?> getUserBehavior() async {
    return _queryAdapter.query('SELECT * FROM user_behavior WHERE id = 1',
        mapper: (Map<String, Object?> row) => UserBehavior(
            id: row['id'] as int,
            avgAmount: row['avg_amount'] as double,
            maxAmount: row['max_amount'] as double,
            txnCount: row['txn_count'] as int,
            lastTxnTime: row['last_txn_time'] as int));
  }

  @override
  Future<void> insertOrUpdateBehavior(UserBehavior behavior) async {
    await _userBehaviorInsertionAdapter.insert(
        behavior, OnConflictStrategy.replace);
  }
}

class _$FraudKeywordsDao extends FraudKeywordsDao {
  _$FraudKeywordsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _fraudKeywordsInsertionAdapter = InsertionAdapter(
            database,
            'fraud_keywords',
            (FraudKeywords item) => <String, Object?>{
                  'id': item.id,
                  'keyword': item.keyword,
                  'category': item.category,
                  'risk_weight': item.riskWeight
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FraudKeywords> _fraudKeywordsInsertionAdapter;

  @override
  Future<List<FraudKeywords>> getAllKeywords() async {
    return _queryAdapter.queryList('SELECT * FROM fraud_keywords',
        mapper: (Map<String, Object?> row) => FraudKeywords(
            id: row['id'] as int?,
            keyword: row['keyword'] as String,
            category: row['category'] as String,
            riskWeight: row['risk_weight'] as int));
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM fraud_keywords');
  }

  @override
  Future<void> insertKeyword(FraudKeywords keyword) async {
    await _fraudKeywordsInsertionAdapter.insert(
        keyword, OnConflictStrategy.abort);
  }
}

class _$FraudFeedbackDao extends FraudFeedbackDao {
  _$FraudFeedbackDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _fraudFeedbackInsertionAdapter = InsertionAdapter(
            database,
            'fraud_feedback',
            (FraudFeedback item) => <String, Object?>{
                  'id': item.id,
                  'upi_hash': item.upiHash,
                  'was_fraud': item.wasFraud,
                  'user_action': item.userAction,
                  'reported_time': item.reportedTime
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<FraudFeedback> _fraudFeedbackInsertionAdapter;

  @override
  Future<List<FraudFeedback>> getAllFeedback() async {
    return _queryAdapter.queryList(
        'SELECT * FROM fraud_feedback ORDER BY reported_time DESC',
        mapper: (Map<String, Object?> row) => FraudFeedback(
            id: row['id'] as int?,
            upiHash: row['upi_hash'] as String,
            wasFraud: row['was_fraud'] as int,
            userAction: row['user_action'] as String,
            reportedTime: row['reported_time'] as int));
  }

  @override
  Future<void> insertFeedback(FraudFeedback feedback) async {
    await _fraudFeedbackInsertionAdapter.insert(
        feedback, OnConflictStrategy.abort);
  }
}

class _$MlFeatureDao extends MlFeatureDao {
  _$MlFeatureDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _mlFeatureInsertionAdapter = InsertionAdapter(
            database,
            'ml_features',
            (MlFeature item) => <String, Object?>{
                  'id': item.id,
                  'scan_id': item.scanId,
                  'amount': item.amount,
                  'is_in_contacts': item.isInContacts,
                  'hour_of_day': item.hourOfDay,
                  'is_new_receiver': item.isNewReceiver,
                  'label': item.label
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MlFeature> _mlFeatureInsertionAdapter;

  @override
  Future<List<MlFeature>> getAllMlFeatures() async {
    return _queryAdapter.queryList('SELECT * FROM ml_features ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => MlFeature(
            id: row['id'] as int?,
            scanId: row['scan_id'] as int,
            amount: row['amount'] as double,
            isInContacts: row['is_in_contacts'] as int,
            hourOfDay: row['hour_of_day'] as int,
            isNewReceiver: row['is_new_receiver'] as int,
            label: row['label'] as int?));
  }

  @override
  Future<MlFeature?> findByScanId(int scanId) async {
    return _queryAdapter.query('SELECT * FROM ml_features WHERE scan_id = ?1',
        mapper: (Map<String, Object?> row) => MlFeature(
            id: row['id'] as int?,
            scanId: row['scan_id'] as int,
            amount: row['amount'] as double,
            isInContacts: row['is_in_contacts'] as int,
            hourOfDay: row['hour_of_day'] as int,
            isNewReceiver: row['is_new_receiver'] as int,
            label: row['label'] as int?),
        arguments: [scanId]);
  }

  @override
  Future<int?> getFeatureCount() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM ml_features',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getCountByUpiId(String upiId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM ml_features JOIN scanned_qr ON ml_features.scan_id = scanned_qr.id WHERE scanned_qr.upi_id = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [upiId]);
  }

  @override
  Future<int?> getRecentScanCount(int timestamp) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM ml_features JOIN scanned_qr ON ml_features.scan_id = scanned_qr.id WHERE scanned_qr.scan_time > ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [timestamp]);
  }

  @override
  Future<int?> getSafeHighValueCount() async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM ml_features WHERE amount >= 10000 AND label = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getTotalNewReceiverCount() async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM ml_features WHERE is_new_receiver = 1',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<int?> getSafeNewReceiverCount() async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM ml_features WHERE is_new_receiver = 1 AND label = 0',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> updateLabel(
    int scanId,
    int label,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE ml_features SET label = ?2 WHERE scan_id = ?1',
        arguments: [scanId, label]);
  }

  @override
  Future<void> insertMlFeature(MlFeature feature) async {
    await _mlFeatureInsertionAdapter.insert(feature, OnConflictStrategy.abort);
  }
}
