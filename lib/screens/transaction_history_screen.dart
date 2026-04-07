import 'package:flutter/material.dart';
import '../widgets/transaction/transaction_list.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedRange = 'Last Month';

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color.fromARGB(255, 0, 57, 104);
    const Color bgColor = Color(0xFFF7F8FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(primaryBlue),
          _buildEStatementButton(context, primaryBlue),
          const Expanded(
            child: TransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(Color color) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Showing results for:',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  selectedRange,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.keyboard_arrow_down, size: 16, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEStatementButton(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: InkWell(
        onTap: () => _showDownloadDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.picture_as_pdf_outlined, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Download E-Statement',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Get your detailed transaction report',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Downloading Statement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating your PDF e-statement...'),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('E-Statement downloaded successfully!')),
      );
    });
  }
}
