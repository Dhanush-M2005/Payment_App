import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _pn;
  String? _upiId;
  String? _upiUri;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _upiUri = args?['upiUri'];
    if (_upiUri != null) {
      final uri = Uri.tryParse(_upiUri!);
      _upiId = uri?.queryParameters['pa'];
      _pn = uri?.queryParameters['pn'];
    } else {
      _upiId = args?['upiId'];
      _pn = args?['pn'];
    }
  }

  void _proceed() {
    if (_amountController.text.isEmpty) return;

    final String amount = double.parse(
      _amountController.text,
    ).toStringAsFixed(2);
    final String tr = "SAFE${DateTime.now().millisecondsSinceEpoch}";
    final String tn = "Payment via SafeUPI";
    final String pn = _pn ?? "Recipient";
    final String upiId = _upiId ?? "unknown@upi";

    String finalUriString;
    if (_upiUri != null && _upiUri!.startsWith("upi://pay")) {
      final Uri base = Uri.parse(_upiUri!);
      final Map<String, String> params = Map.from(base.queryParameters);
      params['am'] = amount;
      params['cu'] = 'INR';
      params['tr'] = tr;
      params['tn'] = tn;
      // Ensure 'pn' is present, using the fallback if necessary
      params['pn'] = pn;

      finalUriString = base.replace(queryParameters: params).toString();
    } else {
      finalUriString =
          "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(pn)}&am=$amount&cu=INR&tr=$tr&tn=${Uri.encodeComponent(tn)}";
    }

    // Pass payment details to Risk Screen
    Navigator.pushNamed(
      context,
      '/risk',
      arguments: {
        'upiUri': finalUriString,
        'upiId': upiId,
        'amount': amount,
        'pn': pn,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Amount"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(_upiId?.substring(0, 1).toUpperCase() ?? "U"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paying to",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _upiId ?? "Receiver",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: -0.5, end: 0),

            const SizedBox(height: 60),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: "₹",
                border: InputBorder.none,
                hintText: "0",
              ),
            ).animate().scale(),

            const SizedBox(height: 40),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceed,
                child: const Text("Continue", style: TextStyle(fontSize: 18)),
              ),
            ).animate().slideY(begin: 1, end: 0),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
