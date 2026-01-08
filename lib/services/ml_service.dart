import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../database/app_database.dart';
import '../database/entities/ml_feature.dart';

class MlService {
  final AppDatabase db;

  MlService(this.db);

  /// Extracts ML features for a transaction.
  /// This should be called after the ScannedQr record is inserted to ensure
  /// frequencies and "is_new_receiver" are calculated correctly.
  Future<MlFeature> extractFeatures({
    required int scanId,
    required String upiId,
    required double amount,
    required bool isInContacts,
    required String qrType,
  }) async {
    final now = DateTime.now();

    // 1. hour_of_day (0-23)
    int hourOfDay = now.hour;

    // 2. qr_type (encoded as 0=P2P, 1=MERCHANT)
    int qrTypeEncoded = (qrType.toUpperCase().contains('MERCHANT')) ? 1 : 0;

    // 3. is_new_receiver
    // Check history for this UPI ID. If count is 1, it's the first time (including current).
    final history = await db.scannedQrDao.getScansByUpi(upiId);
    int isNewReceiver = (history.length <= 1) ? 1 : 0;

    // 4. scan_frequency (Total scans in last 24 hours)
    final oneDayAgo = now
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    final recentCount =
        await db.mlFeatureDao.getRecentScanCount(oneDayAgo) ?? 0;
    int scanFrequency = recentCount + 1; // +1 for the current transaction

    return MlFeature(
      scan_id: scanId,
      amount: amount,
      is_in_contacts: isInContacts ? 1 : 0,
      qr_type: qrTypeEncoded,
      hour_of_day: hourOfDay,
      is_new_receiver: isNewReceiver,
      scan_frequency: scanFrequency,
      // label: null, // To be filled later if fraud is detected
    );
  }

  /// The ONNX session for the cold start model
  OrtSession? _session;

  Future<void> _initSession() async {
    if (_session != null) return;

    // Initialize ONNX Runtime Environment
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();

    try {
      final rawModel = await rootBundle.load('assets/ml/cold_start_model.onnx');
      _session = OrtSession.fromBuffer(
        rawModel.buffer.asUint8List(),
        sessionOptions,
      );
    } catch (e) {
      print("Error loading ONNX model: $e");
    }
  }

  /// Performs inference using the ONNX model.
  /// Returns 0 for Safe, 1 for Fraud.
  Future<int> predict(MlFeature feature) async {
    await _initSession();
    if (_session == null) return 0; // Fallback to safe if model fails to load

    try {
      final inputData = feature.toFeatureList();
      final shape = [1, 6];
      // Use the proper factory method for the tensor
      final inputOrtValue = OrtValueTensor.createTensorWithDataList(
        inputData,
        shape,
      );

      // We use the first input name from the model
      final inputName = _session!.inputNames.first;
      final inputs = {inputName: inputOrtValue};

      final outputs = _session!.run(OrtRunOptions(), inputs);

      // Cleanup inputs
      inputOrtValue.release();

      if (outputs.isNotEmpty) {
        // Output is typically a tensor of labels or probabilities
        final firstOutput = outputs.first!;
        final resultValue = firstOutput.value;

        // Release all outputs to prevent memory leaks
        for (var element in outputs) {
          element?.release();
        }

        if (resultValue is List<int>) {
          return resultValue.first;
        } else if (resultValue is List<double>) {
          // If it's a probability, assume > 0.5 is fraud
          return resultValue.first > 0.5 ? 1 : 0;
        } else if (resultValue is Int64List) {
          return resultValue.first.toInt();
        } else if (resultValue is Float32List) {
          // Some models output probabilities as Float32List
          return resultValue.first > 0.5 ? 1 : 0;
        }
      }
    } catch (e) {
      print("Error during ONNX inference: $e");
    }
    return 0;
  }

  /// Helper to get the model type (Cold Start vs Personalized)
  Future<String> getModelType() async {
    final count = await db.mlFeatureDao.getFeatureCount() ?? 0;
    return count < 10 ? "COLD_START" : "PERSONALIZED";
  }
}
