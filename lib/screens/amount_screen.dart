import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/contact_service.dart';

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
  Contact? _matchedContact;
  bool _isNumberUpi = false;
  bool _hasChecked = false;
  String _qrType = 'P2P';
  bool _userConfirmedKnowledge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasChecked) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _upiUri = args?['upiUri'];
    if (_upiUri != null) {
      final uri = Uri.tryParse(_upiUri!);
      _upiId = uri?.queryParameters['pa'];
      _pn = uri?.queryParameters['pn'];
      // MC (Merchant Code) presence indicates a merchant QR
      _qrType = uri?.queryParameters.containsKey('mc') == true
          ? 'MERCHANT'
          : 'P2P';
    } else {
      _upiId = args?['upiId'];
      _pn = args?['pn'];
      _qrType = 'P2P'; // Manual entry is usually P2P
    }

    if (_upiId != null) {
      _hasChecked = true;
      _performContactCheck();
    }
  }

  Future<void> _performContactCheck() async {
    if (_upiId == null) return;

    _isNumberUpi = ContactService.startsWithNumber(_upiId!);

    if (_isNumberUpi) {
      // Check contacts
      final contact = await ContactService.findContactByPhone(_upiId!);
      if (mounted) {
        setState(() {
          _matchedContact = contact;
        });
      }
    }

    // Always show popup for verification as requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showKnowledgePopup();
    });
  }

  void _showKnowledgePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Recipient"),
        content: Text(
          "You are paying to $_upiId. Whether you know the concerned person?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _userConfirmedKnowledge = false);
              Navigator.pop(context);
            },
            child: const Text("NO, I DON'T KNOW"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _userConfirmedKnowledge = true);
              Navigator.pop(context);
            },
            child: const Text("YES, I KNOW"),
          ),
        ],
      ),
    );
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
        'isInContacts': _isNumberUpi
            ? (_matchedContact != null)
            : _userConfirmedKnowledge,
        'qrType': _qrType,
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
                    backgroundImage: (_matchedContact?.photo != null)
                        ? MemoryImage(_matchedContact!.photo!)
                        : null,
                    child: (_matchedContact?.photo == null)
                        ? Text(_upiId?.substring(0, 1).toUpperCase() ?? "U")
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Paying to",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (_matchedContact != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "In Contacts",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _matchedContact?.displayName ?? _upiId ?? "Receiver",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_matchedContact != null)
                          Text(
                            _upiId ?? "",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
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
