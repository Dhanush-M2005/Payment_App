import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _upiController = TextEditingController();

  void _proceedToAmount(Map<String, dynamic> args) {
    if (args['upiId'] == null && args['upiUri'] == null) return;

    Navigator.pushNamed(context, '/amount', arguments: args);
  }

  Future<void> _handleScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _proceedToAmount(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UPI Shield"),
        automaticallyImplyLeading: false, // Hide back button
        actions: [
          IconButton(
            icon: const Icon(Icons.shield, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Big Scan Button
              InkWell(
                onTap: _handleScan,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Scan QR Code",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(delay: 200.ms),
              const SizedBox(height: 20),

              const SizedBox(height: 30),

              // Input Field
              Text(
                "Or pay to contact",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/pay_anyone');
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _upiController,
                    decoration: InputDecoration(
                      hintText: "Enter UPI ID or Phone Number",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(
                        Icons.arrow_forward,
                      ), // Just visual
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Quick Actions
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.phone_android, "Recharge"),
                  _buildQuickAction(Icons.lightbulb_outline, "Electricity"),
                  _buildQuickAction(Icons.tv, "DTH"),
                  _buildQuickAction(Icons.receipt_long, "Bills"),
                ],
              ).animate().slideY(
                begin: 0.5,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

              const SizedBox(height: 40),

              // Transaction History Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/transactions');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade700,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text(
                  "See Your Transactions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
