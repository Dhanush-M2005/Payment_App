import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../database/app_database.dart';
import '../database/entities/ml_feature.dart';

class MlService {
  final AppDatabase db;

  MlService(this.db);

  /// Extracts ML features for a transaction.
  /// This should be called after the ScannedQr record is inserted to ensure
  /// "is_new_receiver" is calculated correctly.
  Future<MlFeature> extractFeatures({
    required int scanId,
    required String upiId,
    required double amount,
    required bool isInContacts,
  }) async {
    final now = DateTime.now();

    // 1. hour_of_day (0-23)
    int hourOfDay = now.hour;

    // 2. is_new_receiver
    // Check history for this UPI ID. If count is 1, it's the first time (including current).
    final history = await db.scannedQrDao.getScansByUpi(upiId);
    int isNewReceiver = (history.length <= 1) ? 1 : 0;

    return MlFeature(
      scanId: scanId,
      amount: amount,
      isInContacts: isInContacts ? 1 : 0,
      hourOfDay: hourOfDay,
      isNewReceiver: isNewReceiver,
      // label: null, // To be filled later if fraud is detected
    );
  }

  /// The ONNX session for the random forest model
  OrtSession? _session;

  Future<void> _initSession() async {
    if (_session != null) return;

    // Initialize ONNX Runtime Environment
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();

    try {
      final rawModel = await rootBundle.load(
        'assets/ml/random_forest_model.onnx',
      );
      _session = OrtSession.fromBuffer(
        rawModel.buffer.asUint8List(),
        sessionOptions,
      );
    } catch (e) {
      debugPrint("Error loading ONNX model: $e");
    }
  }

  /// Performs inference using the ONNX model.
  /// Returns 0 for Safe, 1 for Fraud.
  Future<int> predict(MlFeature feature) async {
    await _initSession();
    if (_session == null) return 0; // Fallback to safe if model fails to load

    try {
      final inputData = feature.toFeatureList();
      final shape = [1, 4];

      debugPrint("--- ONNX Inference Input ---");
      debugPrint("Features: $inputData");
      debugPrint("Shape: $shape");

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

        int basePrediction = 0;
        double baseProb = 0.0;

        if (resultValue is List<int>) {
          basePrediction = resultValue.first;
          baseProb = basePrediction == 1 ? 0.8 : 0.2;
        } else if (resultValue is List<double>) {
          baseProb = resultValue.first; // Assuming prob of class 1
          basePrediction = baseProb > 0.5 ? 1 : 0;
        } else if (resultValue is Int64List) {
          basePrediction = resultValue.first.toInt();
          baseProb = basePrediction == 1 ? 0.8 : 0.2;
        } else if (resultValue is Float32List) {
          final res = resultValue.first;
          // In some sklearn exports, output can be [prob_0, prob_1] or just prob_1
          // Here assuming single value float
          baseProb = res;
          basePrediction = res > 0.5 ? 1 : 0;
        } else {
          // Fallback
          if (resultValue is List && resultValue.isNotEmpty) {
            basePrediction = resultValue.first == 1 ? 1 : 0;
            baseProb = basePrediction == 1 ? 0.8 : 0.2;
          }
        }

        debugPrint("ONNX Base Prediction: $basePrediction (Prob: $baseProb)");

        // --- ADAPTIVE LOGIC (SELF-TRAINING) ---
        if (basePrediction == 1) {
          final modelType = await getModelType();
          if (modelType == "PERSONALIZED") {
            debugPrint(
              "[Adaptive] Analyzing user history for personalisation...",
            );
            double adjustedProb = baseProb;

            // 1. High Value Comfort Analysis
            if (feature.amount > 10000) {
              final safeHighValueCount =
                  await db.mlFeatureDao.getSafeHighValueCount() ?? 0;
              // Rule: Has done it safely >= 3 times
              if (safeHighValueCount >= 3) {
                debugPrint(
                  " -> Pattern found: User makes safe high-value payments.",
                );
                adjustedProb -= 0.25;
              }
            }

            // 2. New Receiver Comfort Analysis
            if (feature.isNewReceiver == 1) {
              final totalNew =
                  await db.mlFeatureDao.getTotalNewReceiverCount() ?? 0;
              if (totalNew > 0) {
                final safeNew =
                    await db.mlFeatureDao.getSafeNewReceiverCount() ?? 0;
                final ratio = safeNew / totalNew;
                // Rule: > 80% success rate with new people
                if (ratio > 0.8) {
                  debugPrint(" -> Pattern found: User trusts new receivers.");
                  adjustedProb -= 0.20;
                }
              }
            }

            debugPrint(
              "[Adaptive] Base Risk: $baseProb | Adjusted Risk: $adjustedProb",
            );

            if (adjustedProb < 0.5) {
              debugPrint(
                "✅ ADAPTIVE OVERRIDE: Transaction Marked Safe based on History.",
              );
              return 0;
            }
          }
        }

        return basePrediction;
      }
    } catch (e) {
      debugPrint("Error during ONNX inference: $e");
    }
    return 0;
  }

  /// Manually marks a transaction as safe (Feedback Loop).
  Future<void> markSafe(int scanId) async {
    await db.mlFeatureDao.updateLabel(scanId, 0);
    await db.scannedQrDao.markAsSafe(scanId);
    debugPrint("Transaction $scanId marked as SAFE by user override.");
  }

  /// Helper to get the model type (Cold Start vs Personalized)
  Future<String> getModelType() async {
    final count = await db.mlFeatureDao.getFeatureCount() ?? 0;
    return count < 10 ? "COLD_START" : "PERSONALIZED";
  }
}
