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
        title: Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Cards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: ListTile(
                leading: Icon(Icons.credit_card, color: context.colors.primary),
                title: const Text('•••• •••• •••• 4242', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Expires 12/26'),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: context.colors.error),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Saved UPI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: ListTile(
                leading: Icon(Icons.payment, color: context.colors.primary),
                title: const Text('user@upi', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: context.colors.error),
                  onPressed: () {},
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add New Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

