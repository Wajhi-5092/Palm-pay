import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _fathersNameController = TextEditingController();
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

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final fathersName = _fathersNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    final city = _cityController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().register(
        name: name,
        fathersName: fathersName,
        gender: _selectedGender!,
        email: email,
        phone: phone,
        cnic: cnic,
        city: city,
        address: address,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
                  _buildInputField(
                    controller: _fathersNameController,
                    label: 'Father\'s Name',
                    hint: 'Enter your father\'s name',
                    icon: Icons.people_outline_rounded,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
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
              hint: Text('Select Gender', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5)),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: isPassword && !isPasswordVisible,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  keyboardType: (isPhone || isNumber) ? TextInputType.phone : TextInputType.text,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
                        : Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 22),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                            onPressed: onToggleVisibility,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
    return Container(
      width: 300,
      height: 300,
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
