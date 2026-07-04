import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Simulate OTP send delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/auth/phone/otp', extra: 'mock-verification-id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => context.go('/onboarding'),
                icon: const Icon(Icons.arrow_back_rounded),
                color: context.colors.textPrimary,
                padding: const EdgeInsets.all(16),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.colors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: context.colors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Enter your\nmobile number',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'We\'ll send a 6-digit OTP to verify your number. Standard rates apply.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Phone field
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          // Country code
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: context.colors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🇮🇳',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: context.colors.textSecondary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          // Phone number input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '00000 00000',
                                hintStyle: TextStyle(
                                  color: context.colors.textHint,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                fillColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Send OTP button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Send OTP'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Terms
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






