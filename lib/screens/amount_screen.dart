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

  // Merchant Detection State
  String _qrType = 'P2P';
  bool _isMerchant = false;
  String? _merchantCategory;

  bool _userConfirmedKnowledge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasChecked) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _upiUri = args?['upiUri'];

    if (_upiUri != null) {
      // Fix malformed URIs (e.g. spaces in name) to ensure parsing succeeds
      String cleanUri = _upiUri!;
      if (cleanUri.contains(" ") && !cleanUri.contains("%20")) {
        cleanUri = cleanUri.replaceAll(" ", "%20");
      }
      _upiUri = cleanUri; // Update class member with cleaned URI

      final uri = Uri.tryParse(cleanUri);
      if (uri != null) {
        _upiId = uri.queryParameters['pa'];
        _pn = uri.queryParameters['pn'];

        // ---------------------------------------------------------
        // MERCHANT DETECTION LOGIC
        // ---------------------------------------------------------
        // Check for multiple merchant indicators: mc, mid, tid
        final String? mc = uri.queryParameters['mc'];
        final String? mid = uri.queryParameters['mid']; // Merchant ID
        final String? tid = uri.queryParameters['tid']; // Terminal ID

        // If any of these exist, treat as Merchant
        if ((mc != null && mc.isNotEmpty && mc != "0000") ||
            (mid != null && mid.isNotEmpty) ||
            (tid != null && tid.isNotEmpty)) {
          _isMerchant = true;
          _qrType = 'MERCHANT';

          if (mc != null && mc.isNotEmpty && mc != "0000") {
            _merchantCategory = _getMerchantCategory(mc);
          } else {
            _merchantCategory = "Verified Merchant";
          }
        } else {
          _isMerchant = false;
          _qrType = 'P2P';
          _merchantCategory = "Personal Payment (P2P)";
        }
      }
    } else {
      _upiId = args?['upiId'];
      _pn = args?['pn'];
      _qrType = 'P2P'; // Manual entry is P2P
      _merchantCategory = "Personal Payment (P2P)";
    }

    if (_upiId != null) {
      _hasChecked = true;
      // Only do contact checks for P2P or Number based UPIs
      if (!_isMerchant) {
        _performContactCheck();
      }
    }
  }

  String _getMerchantCategory(String mc) {
    // Standard MCC Mapping
    switch (mc) {
      case '8062':
      case '8011':
      case '8099':
        return "Merchant: Hospital / Healthcare";
      case '5411':
      case '5499':
        return "Merchant: Grocery / Supermarket";
      case '5812':
      case '5814':
        return "Merchant: Restaurant / Food";
      case '7011':
        return "Merchant: Hotel / Travel";
      case '8398':
        return "Merchant: Trust / Charity";
      case '8661':
        return "Merchant: Religious Organization";
      case '4900':
        return "Merchant: Utilities";
      case '9399':
      case '9311':
        return "Merchant: Government";
      case '5311':
      case '5331':
        return "Merchant: Retail Store";
      default:
        return "Merchant: Busines / General Retail (MCC: $mc)";
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
    } else {
      // Show popup for verification ONLY for non-number (alphabet) UPI IDs
      // And only if it is NOT a verified merchant (already handled by _isMerchant flag skipping this function)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showKnowledgePopup();
      });
    }
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
      params['pn'] = pn; // Update Name if needed

      finalUriString = base.replace(queryParameters: params).toString();
    } else {
      finalUriString =
          "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(pn)}&am=$amount&cu=INR&tr=$tr&tn=${Uri.encodeComponent(tn)}";
    }

    // ---------------------------------------------------------
    // CONDITIONAL FLOW: MERCHANT vs P2P
    // ---------------------------------------------------------

    if (_isMerchant) {
      // DIRECT REDIRECT - SKIP ML
      Navigator.pushNamed(
        context,
        '/redirect',
        arguments: {'upiUri': finalUriString, 'upiId': upiId, 'amount': amount},
      );
    } else {
      // P2P - GO TO RISK SCREEN (Run ML)
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
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color/icon based on Merchant vs P2P
    final Color statusColor = _isMerchant ? Colors.purple : Colors.blue;
    final IconData statusIcon = _isMerchant ? Icons.store : Icons.person;

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Amount"), centerTitle: true),
      body: CustomScrollView(
        slivers: [
          // 1. SCROLLABLE CONTENT (Top)
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: 0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // MERCHANT / TYPE INDICATOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          _merchantCategory ?? "Checking...",
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          backgroundImage: (_matchedContact?.photo != null)
                              ? MemoryImage(_matchedContact!.photo!)
                              : null,
                          radius: 28,
                          child: (_matchedContact?.photo == null)
                              ? Icon(
                                  _isMerchant ? Icons.store : Icons.person,
                                  color: statusColor,
                                  size: 28,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Details
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
                                _matchedContact?.displayName ??
                                    _pn ??
                                    _upiId ??
                                    "Receiver",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      prefixText: "₹",
                      border: InputBorder.none,
                      hintText: "0",
                    ),
                  ).animate().scale(),

                  if (!_isMerchant)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "ML Check will be applied",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. STICKY FOOTER (Fills remaining space, button at bottom)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 40), // Minimum spacer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMerchant
                            ? Colors.purple
                            : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isMerchant
                            ? "Proceed to Pay (Secure)"
                            : "Analyze & Pay",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ).animate().slideY(begin: 1, end: 0),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
