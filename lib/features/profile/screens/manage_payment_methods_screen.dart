import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() => _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState extends State<ManagePaymentMethodsScreen> {
  String _selectedPayment = 'gpay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text('Maruti Stationery', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
        actions: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: context.colors.success),
              const SizedBox(width: 4),
              Text('Secure', style: TextStyle(color: context.colors.success, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        const SizedBox(height: 16),
                        
                        Text('UPI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedPayment.contains('pay') ? context.colors.primary : context.colors.border),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption('gpay', 'Google Pay', Icons.payment),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('phonepe', 'PhonePe', Icons.account_balance_wallet),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('paytm', 'Paytm', Icons.qr_code),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Text('CARDS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedPayment == 'card' ? context.colors.primary : context.colors.border),
                          ),
                          child: _buildPaymentOption('card', 'Credit / Debit Card', Icons.credit_card, subtitle: 'Visa, Mastercard, RuPay & more'),
                        ),

                        const SizedBox(height: 24),
                        Text('OTHER OPTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ['netbanking', 'cod'].contains(_selectedPayment) ? context.colors.primary : context.colors.border),
                          ),
                          child: Column(
                            children: [
                              _buildPaymentOption('netbanking', 'Netbanking', Icons.account_balance),
                              Divider(height: 1, color: context.colors.divider),
                              _buildPaymentOption('cod', 'Cash on Delivery', Icons.money, subtitle: 'Pay at your doorstep'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.security, size: 16, color: context.colors.success),
                            const SizedBox(width: 4),
                            Text('100% Secure Checkout   |   Powered by Razorpay', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String id, String title, IconData icon, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: _selectedPayment == id ? context.colors.primary : context.colors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Radio<String>(
        value: id,
        groupValue: _selectedPayment,
        activeColor: context.colors.primary,
        onChanged: (val) {
          setState(() {
            _selectedPayment = val!;
          });
        },
      ),
      onTap: () {
        setState(() {
          _selectedPayment = id;
        });
      },
    );
  }
}

