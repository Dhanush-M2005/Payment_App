import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../database/entities/scanned_qr.dart';
import '../services/risk_services.dart';

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final RiskService _riskService = RiskService();

  @override
  void initState() {
    super.initState();
    // Start analysis after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      final String upiId = args['upiId'];
      final String amountStr = args['amount'];
      final double amount = double.tryParse(amountStr) ?? 0.0;

      // 1. Analyze Risk
      int riskScore = await _riskService.analyzeRisk(upiId, amount);

      // 2. Save to Database (Non-blocking ideally, but we await for simplicity. Catch errors separately)
      if (mounted) {
        try {
          final db = Provider.of<AppDatabase>(context, listen: false);
          final String pn = args['pn'] ?? "Unknown";

          final scan = ScannedQr(
            upiId: upiId,
            payeeName: pn,
            qrType: 'P2P',
            scanTime: DateTime.now().millisecondsSinceEpoch,
            amount: amount,
            riskResult: riskScore < 50 ? 'SAFE' : 'WARN',
          );

          await db.scannedQrDao.insertScan(scan);
        } catch (dbError) {
          debugPrint("Database Error: $dbError");
          // Proceed even if DB fails
        }
      }

      if (!mounted) return;

      // 3. Navigate
      if (riskScore < 50) {
        Navigator.pushReplacementNamed(context, '/redirect', arguments: args);
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/warning',
          arguments: {...args, 'riskScore': riskScore},
        );
      }
    } catch (e) {
      debugPrint("Risk Analysis Error: $e");
      // Fallback: Just go to redirect if something blows up
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
        Navigator.pushReplacementNamed(context, '/redirect', arguments: args);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 40),
            Text(
                  "Analyzing transaction risk...",
                  style: Theme.of(context).textTheme.titleLarge,
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2.seconds, color: Colors.blue.shade200),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Isolation Forest model runs here (mocked)",
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
