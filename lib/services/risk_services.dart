import 'dart:math';

class RiskService {
  /// Simulates Isolation Forest Risk Analysis
  /// Returns a risk score between 0 and 100.
  /// 0-49: Low Risk
  /// 50-100: High Risk
  Future<int> analyzeRisk(String upiId, double amount) async {
    // Mock Delay to simulate computation/network call
    await Future.delayed(const Duration(seconds: 1));

    // Simple mock logic for demo purposes
    if (amount > 5000) {
      return 78; // High risk for demo
    } else if (upiId.contains("fraud")) {
      return 95;
    } else {
      // Random low risk
      return Random().nextInt(30);
    }
  }
}
