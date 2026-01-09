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
      scan_id: scanId,
      amount: amount,
      is_in_contacts: isInContacts ? 1 : 0,
      hour_of_day: hourOfDay,
      is_new_receiver: isNewReceiver,
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
      final shape = [1, 4];

      print("--- ONNX Inference Input ---");
      print("Features: $inputData");
      print("Shape: $shape");

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
          final res = resultValue.first;
          print(
            "ONNX Model Prediction: ${res == 1 ? 'FRAUD (1)' : 'SAFE (0)'}",
          );
          return res;
        } else if (resultValue is List<double>) {
          final res = resultValue.first;
          print("ONNX Model Prediction (Probability): $res");
          return res > 0.5 ? 1 : 0;
        } else if (resultValue is Int64List) {
          final res = resultValue.first.toInt();
          print(
            "ONNX Model Prediction: ${res == 1 ? 'FRAUD (1)' : 'SAFE (0)'}",
          );
          return res;
        } else if (resultValue is Float32List) {
          final res = resultValue.first;
          print("ONNX Model Prediction (Float32): $res");
          return res > 0.5 ? 1 : 0;
        } else {
          print(
            "ONNX Model Prediction (Unknown Type: ${resultValue.runtimeType}): $resultValue",
          );
          // Fallback check: if it's some other list type, try to get the first element
          if (resultValue is List && resultValue.isNotEmpty) {
            return resultValue.first == 1 ? 1 : 0;
          }
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
