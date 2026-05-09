// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:paypalm/services/auth_service.dart';
import 'package:paypalm/services/mpin_service.dart';
import 'package:paypalm/services/connectivity_service.dart';
import 'package:paypalm/widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  final MpinService _mpinService = MpinService();
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Dismiss the keyboard instantly so the Snackbar renders completely at the bottom
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    final city = _cityController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedGender == null) {
      CustomSnackbar.show(
        context: context,
        message: 'Please fill all required fields',
        type: SnackbarType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      CustomSnackbar.show(
        context: context,
        message: 'Passwords do not match',
        type: SnackbarType.error,
      );
      return;
    }

    if (!await _connectivity.isInternetAvailable()) {
      if (!mounted) return;
      final dialogFuture = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Waiting for connection…',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      );

      try {
        await _connectivity.onInternetAvailable.firstWhere((v) => v == true);
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      await dialogFuture;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().register(
        name: name,
        gender: _selectedGender!,
        email: email,
        phone: phone,
        cnic: cnic,
        city: city,
        address: address,
        password: password,
      );

      if (!mounted) return;

      CustomSnackbar.show(
        context: context,
        message: 'Account created successfully!',
        type: SnackbarType.success,
      );

      await _maybeOfferMpinSetup();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _maybeOfferMpinSetup() async {
    final hasMpin = await _mpinService.hasMpin();
    if (hasMpin || !mounted) return;

    final mpinController = TextEditingController();
    final confirmController = TextEditingController();
    bool enableOnReopen = true;
    int mpinLength = 4;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set MPIN for Quick Login'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Create your MPIN to login instantly when reopening.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 4,
                            groupValue: mpinLength,
                            onChanged: (v) {
                              setDialogState(() => mpinLength = v ?? 4);
                              mpinController.clear();
                              confirmController.clear();
                            },
                            title: const Text('4-digit'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            value: 6,
                            groupValue: mpinLength,
                            onChanged: (v) {
                              setDialogState(() => mpinLength = v ?? 6);
                              mpinController.clear();
                              confirmController.clear();
                            },
                            title: const Text('6-digit'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: mpinController,
                      keyboardType: TextInputType.number,
                      maxLength: mpinLength,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'MPIN',
                        counterText: '',
                      ),
                    ),
                    TextField(
                      controller: confirmController,
                      keyboardType: TextInputType.number,
                      maxLength: mpinLength,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm MPIN',
                        counterText: '',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enableOnReopen,
                      onChanged: (value) {
                        setDialogState(() => enableOnReopen = value);
                      },
                      title: const Text('Use MPIN on every app reopen'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () async {
                    final mpin = mpinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (mpin.length != mpinLength ||
                        int.tryParse(mpin) == null) {
                      return;
                    }
                    if (mpin != confirm) {
                      return;
                    }
                    await _mpinService.setMpin(mpin);
                    await _mpinService.setEnabledOnReopen(enableOnReopen);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save MPIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandTeal = Color(0xFF00D1B2);
    const Color accentBlue = Color(0xFF3A86FF);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0F172A)
                ],
              ),
            ),
          ),

          // 2. Ambient Glows
          Positioned(
            top: -100,
            left: -50,
            child: _AmbientGlow(color: brandTeal.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _AmbientGlow(color: accentBlue.withValues(alpha: 0.15)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Header
                  const Text(
                    'Join PayPalm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your palm-secure account',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Inputs Section 1: Basic Info
                  _buildInputField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Gender Selection (Custom Styled)
                  const Text(
                    'Gender',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGenderDropdown(),

                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '3XX XXXXXXX',
                    icon: Icons.phone_outlined,
                    isPhone: true,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _cnicController,
                    label: 'CNIC',
                    hint: 'XXXXX-XXXXXXX-X',
                    icon: Icons.badge_outlined,
                    isNumber: true,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter your city',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter your full address',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),

                  const SizedBox(height: 48),

                  // Register Button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleRegister,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [accentBlue, Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: brandTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: Text('Select Gender',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.arrow_drop_down,
                  color: Colors.white.withValues(alpha: 0.5)),
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    bool isPhone = false,
    bool isNumber = false,
    VoidCallback? onToggleVisibility,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: isPassword && !isPasswordVisible,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  keyboardType: (isPhone || isNumber)
                      ? TextInputType.phone
                      : TextInputType.text,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    prefixIcon: isPhone
                        ? Container(
                            padding: const EdgeInsets.only(left: 20, right: 8),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+92 ',
                                  style: TextStyle(
                                    color: Color(0xFF00D1B2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                  child: VerticalDivider(
                                    color: Colors.white24,
                                    thickness: 1,
                                    width: 20,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Icon(icon,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 22),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                            onPressed: onToggleVisibility,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  const _AmbientGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final glowSize = (shortestSide * 0.75).clamp(220.0, 360.0);

    return Container(
      width: glowSize,
      height: glowSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
