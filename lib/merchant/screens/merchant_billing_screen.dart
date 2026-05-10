import 'package:flutter/material.dart';
import 'package:paypalm/user/screens/palm_scan_screen.dart';
import 'package:uuid/uuid.dart';

class MerchantBillingScreen extends StatefulWidget {
  const MerchantBillingScreen({super.key});

  @override
  State<MerchantBillingScreen> createState() => _MerchantBillingScreenState();
}

class _MerchantBillingScreenState extends State<MerchantBillingScreen> {
  final _amountController = TextEditingController();

  void _proceedToScan() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    final checkoutSessionId = const Uuid().v4();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PalmScanScreen(
          isRegistration: false,
          billAmount: amount,
          checkoutSessionId: checkoutSessionId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Generate Bill', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 80, color: Color(0xFF3A86FF)),
            const SizedBox(height: 24),
            const Text(
              'Enter Bill Amount',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: 'PKR ',
                prefixStyle: const TextStyle(fontSize: 32, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF3A86FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _proceedToScan,
                icon: const Icon(Icons.pan_tool_rounded, color: Colors.white),
                label: const Text(
                  'Scan to Charge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
