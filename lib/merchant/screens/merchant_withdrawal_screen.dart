import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';
import '../../models/merchant_model.dart';
import '../../models/withdrawal_model.dart';
import '../../widgets/custom_snackbar.dart';

class MerchantWithdrawalScreen extends StatefulWidget {
  const MerchantWithdrawalScreen({super.key});

  @override
  State<MerchantWithdrawalScreen> createState() =>
      _MerchantWithdrawalScreenState();
}

class _MerchantWithdrawalScreenState extends State<MerchantWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();

  WithdrawalMethod _selectedMethod = WithdrawalMethod.bankTransfer;
  Merchant? _merchant;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _merchantService = MerchantService();

  @override
  void initState() {
    super.initState();
    _loadMerchant();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchant() async {
    try {
      _merchant = await _merchantService.getCurrentMerchant();
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Failed to load merchant data',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      CustomSnackbar.show(
        context: context,
        message: 'Invalid amount',
        type: SnackbarType.error,
      );
      return;
    }

    if (_merchant == null || amount > _merchant!.walletBalance) {
      CustomSnackbar.show(
        context: context,
        message: 'Insufficient balance',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _merchantService.requestWithdrawal(
        merchantId: _merchant!.id,
        amount: amount,
        method: _selectedMethod,
        accountDetails: _accountController.text.trim(),
      );

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Withdrawal request submitted successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: e.toString(),
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Withdrawal'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A86FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3A86FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs ${_merchant?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3A86FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Withdrawal Amount (Rs)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Amount is required';
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (_merchant != null && amount > _merchant!.walletBalance) {
                    return 'Amount exceeds available balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Withdrawal Method
              const Text(
                'Withdrawal Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: WithdrawalMethod.values
                    .map((method) => RadioMenuButton<WithdrawalMethod>(
                          value: method,
                          groupValue: _selectedMethod,
                          onChanged: (value) =>
                              setState(() => _selectedMethod = value!),
                          child: Text(_getMethodDisplayName(method)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Account Details
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: _getAccountDetailsLabel(),
                  hintText: _getAccountDetailsHint(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Account details are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Provide complete account details for secure transfer',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A86FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Withdrawal Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMethodDisplayName(WithdrawalMethod method) {
    switch (method) {
      case WithdrawalMethod.bankTransfer:
        return 'Bank Transfer';
      case WithdrawalMethod.easypaisa:
        return 'Easypaisa';
      case WithdrawalMethod.jazzcash:
        return 'JazzCash';
    }
  }

  String _getAccountDetailsLabel() {
    switch (_selectedMethod) {
      case WithdrawalMethod.bankTransfer:
        return 'Bank Account Details';
      case WithdrawalMethod.easypaisa:
        return 'Easypaisa Account Number';
      case WithdrawalMethod.jazzcash:
        return 'JazzCash Account Number';
    }
  }

  String _getAccountDetailsHint() {
    switch (_selectedMethod) {
      case WithdrawalMethod.bankTransfer:
        return 'Account Number: XXXX\nBank Name: XXXX\nAccount Title: XXXX';
      case WithdrawalMethod.easypaisa:
        return 'Enter your Easypaisa mobile number';
      case WithdrawalMethod.jazzcash:
        return 'Enter your JazzCash mobile number';
    }
  }
}
