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

  void _onPay(String upiId, String name) {
    if (upiId.isEmpty) return;

    Navigator.pushNamed(
      context,
      '/amount',
      arguments: {
        'upiId': upiId,
        'pn': name,
        'upiUri':
            null, // Construct URI in AmountScreen if needed or just pass ID
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
