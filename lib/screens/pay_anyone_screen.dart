import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../database/app_database.dart';
import '../database/entities/scanned_qr.dart';

class PayAnyoneScreen extends StatefulWidget {
  const PayAnyoneScreen({super.key});

  @override
  State<PayAnyoneScreen> createState() => _PayAnyoneScreenState();
}

class _PayAnyoneScreenState extends State<PayAnyoneScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact>? _contacts;
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoadingContacts = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });
      }
    }
  }

  // Helper method to map MCC to User-Friendly Category (Copied from ScanScreen)
  String _getCategoryFromMc(String? mc) {
    if (mc == null) return "Grocery/Retail";

    switch (mc) {
      case "8011":
        return "Hospital";
      case "5912":
        return "Pharmacy";
      case "5812":
        return "Restaurant";
      case "5411":
        return "Grocery/Retail";
      case "7011":
        return "Hotel";
      case "8249":
        return "Education";
      case "4111":
        return "Transport";
      default:
        return "Grocery/Retail";
    }
  }

  // Classify payment as Merchant or Personal (Copied & Adapted from ScanScreen)
  Map<String, dynamic> _classifyPayment(String rawValue) {
    Uri? uri = Uri.tryParse(rawValue);
    // Robust parsing fallback
    if (uri == null || !uri.hasQuery) {
      uri = Uri.tryParse(rawValue.replaceFirst("upi://", "https://"));
    }

    final params = uri?.queryParameters ?? {};
    final mc = params['mc'];
    final mode = params['mode'];

    // Logic to determine 'pa' (Payee Address / UPI ID)
    String? pa = params['pa'];
    // If not found in params, and input looks like a VPA, treat input as pa
    if (pa == null && rawValue.contains('@') && !rawValue.contains('://')) {
      pa = rawValue;
    }

    bool isMerchant = false;
    String? merchantType;
    String? detectionSource;

    // CONDITION 1 (NPCI Standard – Highest Priority)
    if (mc != null && mc.isNotEmpty) {
      isMerchant = true;
      merchantType = _getCategoryFromMc(mc);
      detectionSource = "NPCI_MCC";
    }
    // CONDITION 2 (PhonePe / Google Pay Merchant)
    else if (mode == "02") {
      isMerchant = true;
      merchantType = "Grocery/Retail"; // Fallback constant
      detectionSource = "UPI_MODE";
    }
    // CONDITION 3 (Paytm Merchant Specific Rule)
    else if (pa != null && pa.endsWith("@ptys")) {
      isMerchant = true;
      merchantType = "PAYTM_MERCHANT";
      detectionSource = "PAYTM_HANDLE";
    }
    // CONDITION 4 (Fallback)
    else {
      isMerchant = false; // PERSONAL
      detectionSource = "FALLBACK_PERSONAL";
    }

    // "if mcc does not exist keep it as grocery/retail"
    if (isMerchant && merchantType == null) {
      merchantType = "Grocery/Retail";
    }

    return {
      'upiUri': rawValue,
      'isMerchant': isMerchant,
      'merchantType': merchantType,
      'detectionSource': detectionSource,
    };
  }

  void _onPay(String upiId, String name) {
    if (upiId.isEmpty) return;

    // Perform merchant check
    final classification = _classifyPayment(upiId);

    Navigator.pushNamed(
      context,
      '/amount',
      arguments: {
        'upiId': upiId,
        'pn': name,
        'upiUri':
            classification['upiUri'], // Pass the raw value (could be URI or ID)
        'isMerchant': classification['isMerchant'],
        'merchantType': classification['merchantType'],
        'detectionSource': classification['detectionSource'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: const Text("Pay anyone", style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Pay any UPI app using name, number or UPI ID",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter UPI ID or number",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () {
                    // Open contact picker if needed, currently we list them below
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (value) {
                // If user enters a raw UPI ID or number, assume it's a UPI ID for now
                if (value.isNotEmpty) {
                  _onPay(value, "Unknown");
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Recents List (from DB)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recents",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100, // Horizontal list height
            child: FutureBuilder<List<ScannedQr>>(
              future: db.scannedQrDao.getRecentPayees(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // If no recents, maybe show nothing or empty state
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      "No recent payments",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return InkWell(
                      onTap: () => _onPay(item.upiId, item.payeeName),
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text(
                              "Remove Payee",
                              style: TextStyle(color: Colors.black),
                            ),
                            content: Text(
                              "Remove ${item.payeeName.isNotEmpty ? item.payeeName : 'this payee'} from recents?",
                              style: const TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await db.scannedQrDao.deleteScansForUpi(
                                    item.upiId,
                                  );
                                  if (context.mounted) {
                                    setState(() {}); // Refresh list
                                  }
                                },
                                child: const Text(
                                  "Remove",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.blue,
                              child: Text(
                                item.payeeName.isNotEmpty
                                    ? item.payeeName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.payeeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Contacts List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "All people on UPI",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoadingContacts
                ? const Center(child: CircularProgressIndicator())
                : _contacts == null || _contacts!.isEmpty
                ? const Center(
                    child: Text(
                      "No contacts found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _contacts!.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts![index];
                      // Only show contacts with phones
                      if (contact.phones.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final phone = contact.phones.first.number;
                      // In a real app we would check if this phone is registered on UPI.
                      // Here we just display them as potential payees.

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          backgroundImage: (contact.photo != null)
                              ? MemoryImage(contact.photo!)
                              : null,
                          child: (contact.photo == null)
                              ? Text(
                                  contact.displayName.isNotEmpty
                                      ? contact.displayName[0]
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          phone,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        onTap: () {
                          // Assuming phone number can act as UPI ID alias or mapped
                          // For now, just pass the number as UPI ID to test flow
                          _onPay(phone, contact.displayName);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
