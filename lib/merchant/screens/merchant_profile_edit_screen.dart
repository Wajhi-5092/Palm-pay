import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';
import '../../models/merchant_model.dart';
import '../../widgets/custom_snackbar.dart';

class MerchantProfileEditScreen extends StatefulWidget {
  const MerchantProfileEditScreen({super.key});

  @override
  State<MerchantProfileEditScreen> createState() =>
      _MerchantProfileEditScreenState();
}

class _MerchantProfileEditScreenState extends State<MerchantProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  final _merchantService = MerchantService();
  Merchant? _merchant;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _categories = [
    'Retail',
    'Food & Beverage',
    'Electronics',
    'Fashion',
    'Healthcare',
    'Education',
    'Services',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadMerchant();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchant() async {
    try {
      _merchant = await _merchantService.getCurrentMerchant();
      if (_merchant != null) {
        _storeNameController.text = _merchant!.storeName;
        _ownerNameController.text = _merchant!.ownerName;
        _categoryController.text = _merchant!.category;
        _phoneController.text = _merchant!.phone;
        _emailController.text = _merchant!.email;
        _addressController.text = _merchant!.address;
        _cityController.text = _merchant!.city;
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Failed to load profile',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _merchant == null) return;

    setState(() => _isSaving = true);

    try {
      await _merchantService.updateMerchantProfile(_merchant!.id, {
        'storeName': _storeNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'category': _categoryController.text,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
      });

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Profile updated successfully',
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
        setState(() => _isSaving = false);
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
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF3A86FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Name
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Store name is required' : null,
              ),
              const SizedBox(height: 16),

              // Owner Name
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Owner name is required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _categoryController.text.isEmpty
                    ? null
                    : _categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'Business Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => _categoryController.text = value ?? '',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Phone number is required';
                  if (value!.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email is required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'City is required' : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
