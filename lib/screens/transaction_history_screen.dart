import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/entities/scanned_qr.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Access the database from Provider
    final database = Provider.of<AppDatabase>(context);
    final dao = database.scannedQrDao;

    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: FutureBuilder<List<ScannedQr>>(
        future: dao.getAllScans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final scans = snapshot.data;

          if (scans == null || scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions found",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: scans.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final scan = scans[index];
              final date = DateTime.fromMillisecondsSinceEpoch(scan.scanTime);
              final formattedDate = DateFormat(
                'MMM dd, yyyy • hh:mm a',
              ).format(date);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForRisk(scan.riskResult),
                    child: Icon(
                      _getIconForRisk(scan.riskResult),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    scan.payeeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scan.upiId, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${(scan.amount ?? 0.0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _getTextColorForRisk(scan.riskResult),
                        ),
                      ),
                      Text(
                        scan.riskResult,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getTextColorForRisk(scan.riskResult),
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
    );
  }

  Color _getColorForRisk(String result) {
    switch (result) {
      case 'SAFE':
        return Colors.green;
      case 'WARN':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForRisk(String result) {
    switch (result) {
      case 'SAFE':
        return Icons.check;
      case 'WARN':
        return Icons.warning_amber_rounded;
      case 'HIGH':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  Color _getTextColorForRisk(String result) {
    switch (result) {
      case 'SAFE':
        return Colors.green.shade700;
      case 'WARN':
        return Colors.orange.shade800;
      case 'HIGH':
        return Colors.red.shade700;
      default:
        return Colors.blue;
    }
  }
}
