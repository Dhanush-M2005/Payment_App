import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../database/entities/scanned_qr.dart';
import '../database/daos/scanned_qr_dao.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  Future<List<ScannedQr>>? _scansFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scansFuture ??= Provider.of<AppDatabase>(
      context,
      listen: false,
    ).scannedQrDao.getAllScans();
  }

  void _refresh() {
    setState(() {
      _scansFuture = Provider.of<AppDatabase>(
        context,
        listen: false,
      ).scannedQrDao.getAllScans();
    });
  }

  void _toggleSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _onLongPress(int? id) {
    if (id == null) return;
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.add(id);
      });
    }
  }

  Future<void> _deleteSelected(ScannedQrDao dao) async {
    final scans = await _scansFuture;
    if (scans == null) return;

    final scansToDelete = scans
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    if (scansToDelete.isNotEmpty) {
      await dao.deleteScans(scansToDelete);
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected transactions deleted")),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ScannedQrDao dao,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transactions"),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} transactions?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSelected(dao);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the database from Provider
    final database = Provider.of<AppDatabase>(context);
    final dao = database.scannedQrDao;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text("${_selectedIds.length} Selected")
            : const Text("Transaction History"),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteConfirmation(context, dao),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              ]
            : null,
      ),
      body: FutureBuilder<List<ScannedQr>>(
        future: _scansFuture,
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
                child: InkWell(
                  onLongPress: () => _onLongPress(scan.id),
                  onTap: _isSelectionMode
                      ? () => _toggleSelection(scan.id)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    selected: _selectedIds.contains(scan.id),
                    selectedTileColor: Colors.blue.withOpacity(0.1),
                    leading: CircleAvatar(
                      backgroundColor: _getColorForRisk(scan.riskResult),
                      child: _isSelectionMode && _selectedIds.contains(scan.id)
                          ? const Icon(Icons.check, color: Colors.white)
                          : Icon(
                              _getIconForRisk(scan.riskResult),
                              color: Colors.white,
                            ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            scan.payeeName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (scan.isInContacts)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
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
