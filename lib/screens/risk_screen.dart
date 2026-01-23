import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../database/entities/scanned_qr.dart';
import '../services/ml_service.dart';
import '../database/entities/ml_feature.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  bool _isAnalyzing = true;
  int? _mlResult;
  String _statusText = "Analyzing transaction risk...";

  // State variables for debugging
  double _amount = 0;
  bool _isInContacts = false;
  int _isNewReceiver = 1;

  int? _scanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMLInference();
    });
  }

  Future<void> _runMLInference() async {
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final String upiId = args['upiId'];
      final String amountStr = args['amount'];
      final double amount = double.tryParse(amountStr) ?? 0.0;
      final String pn = args['pn'] ?? "Unknown";
      final bool isInContacts = args['isInContacts'] ?? false;
      final String qrType = args['qrType'] ?? 'P2P';

      final db = Provider.of<AppDatabase>(context, listen: false);
      final mlService = MlService(db);

      final history = await db.scannedQrDao.getScansByUpi(upiId);
      final isNewReceiver = (history.isEmpty) ? 1 : 0;

      // Heuristic: Check if transaction amount is within historical range
      bool isAmountSafeBasedOnHistory = false;
      double maxPastAmount = 0;
      if (history.isNotEmpty) {
        // Find the maximum amount previously sent to this receiver
        for (var scan in history) {
          if ((scan.amount ?? 0) > maxPastAmount) {
            maxPastAmount = scan.amount ?? 0;
          }
        }

        // If current amount is <= 1.5x the max past amount, we consider it "in range"
        // This handles the case where the user sends 10000, and has sent 10000 before.
        if (amount > 0 && amount <= (maxPastAmount * 1.5)) {
          isAmountSafeBasedOnHistory = true;
        }
      }

      // Get current hour
      final hourOfDay = DateTime.now().hour;

      // Update state for UI visibility
      if (mounted) {
        setState(() {
          _amount = amount;
          _isInContacts = isInContacts;
          _isNewReceiver = isNewReceiver;
        });
      }

      // 1. Initial artificial delay for "Scanning" feel
      await Future.delayed(1500.ms);

      final mlFeature = MlFeature(
        scanId: 0, // Placeholder
        amount: amount,
        isInContacts: isInContacts ? 1 : 0,
        hourOfDay: hourOfDay,
        isNewReceiver: isNewReceiver,
      );

      debugPrint("--------------------------------------------------");
      debugPrint("ML INFERENCE FLOW STARTED");
      debugPrint("PAYEE: $pn ($upiId)");
      debugPrint(
        "FEATURES: {Amt: $amount, Contact: ${isInContacts ? 1 : 0}, Hour: $hourOfDay, New: $isNewReceiver}",
      );

      int prediction = await mlService.predict(mlFeature);

      // Override Logic
      if (isAmountSafeBasedOnHistory && prediction == 1) {
        debugPrint("!!! HEURISTIC OVERRIDE !!!");
        debugPrint("User has sent money to this receiver before.");
        debugPrint("Current Amount: $amount. Max Past Amount: $maxPastAmount.");
        debugPrint(
          "Conclusion: Transaction is within historical range. Overriding Fraud Warning.",
        );
        prediction = 0; // Force SAFE
      }

      debugPrint("--------------------------------------------------");
      debugPrint("ML INFERENCE RESULT (Final)");
      debugPrint(
        "STATUS: ${prediction == 1 ? '⚠️ FRAUD RISK DETECTED' : '✅ SAFE TRANSACTION'}",
      );
      debugPrint("VALUE: $prediction");
      debugPrint("--------------------------------------------------");

      if (!mounted) return;

      setState(() {
        _mlResult = prediction;
        _isAnalyzing = false;
        _statusText = prediction == 1
            ? "Fraud Risk Detected!"
            : "Transaction Verified Safe";
      });

      // 3. Save to Database
      final scan = ScannedQr(
        upiId: upiId,
        payeeName: pn,
        qrType: qrType,
        scanTime: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        riskResult: prediction == 1 ? 'WARN' : 'SAFE',
        isInContacts: isInContacts,
      );

      final int scanId = await db.scannedQrDao.insertScan(scan);
      _scanId = scanId; // Store scanId in state

      final finalFeature = MlFeature(
        scanId: scanId,
        amount: amount,
        isInContacts: mlFeature.isInContacts,
        hourOfDay: hourOfDay,
        isNewReceiver: isNewReceiver,
        label: prediction,
      );
      await db.mlFeatureDao.insertMlFeature(finalFeature);
    } catch (e) {
      debugPrint("ML Error: $e");
    }
  }

  void _proceed() {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    if (_mlResult == 0) {
      Navigator.pushReplacementNamed(context, '/redirect', arguments: args);
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/warning',
        arguments: {...args, 'riskScore': 90, 'scanId': _scanId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFraud = _mlResult == 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Indicator
              if (_isAnalyzing)
                const SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ).animate().scale(duration: 400.ms)
              else
                Icon(
                  isFraud ? Icons.report_problem : Icons.check_circle,
                  size: 120,
                  color: isFraud ? Colors.red : Colors.green,
                ).animate().scale(curve: Curves.elasticOut),

              const SizedBox(height: 48),

              // Status Text
              Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isAnalyzing
                          ? Colors.black87
                          : (isFraud ? Colors.red : Colors.green),
                    ),
                  )
                  .animate(target: _isAnalyzing ? 1 : 0)
                  .shimmer(duration: 2.seconds),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                _isAnalyzing
                    ? "Our ML model is checking transaction patterns..."
                    : (isFraud
                          ? "Pattern matches known fraud techniques."
                          : "No abnormalities found. Verified by ONNX Runtime."),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),

              const SizedBox(height: 40),

              // Technical Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow("Model Type", "Random Forest V1"),
                    const Divider(),
                    _buildFeatureRow(
                      "Amount Analyzed",
                      "₹${_amount.toStringAsFixed(0)}",
                    ),
                    const Divider(),
                    _buildFeatureRow(
                      "In Contacts?",
                      _isInContacts ? "Yes (1)" : "No (0)",
                    ),
                    const Divider(),
                    _buildFeatureRow(
                      "New Receiver?",
                      _isNewReceiver == 1 ? "Yes (1)" : "No (0)",
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),

              // Action Button
              if (!_isAnalyzing)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _proceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFraud ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isFraud
                          ? "View Warning Details"
                          : "Proceed to Secure Payment",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
