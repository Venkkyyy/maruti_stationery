import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/address_model.dart';
import '../../../providers/address_provider.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/cart');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.inkDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Three-Step Progress Stepper ──────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepItem(
                  stepNumber: '1',
                  label: 'Address',
                  isActive: true,
                ),
                _buildStepLine(isActive: false),
                _buildStepItem(
                  stepNumber: '2',
                  label: 'Payment',
                  isActive: false,
                ),
                _buildStepLine(isActive: false),
                _buildStepItem(
                  stepNumber: '3',
                  label: 'Review',
                  isActive: false,
                ),
              ],
            ),
          ),

          // ── Address Selection List ───────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Shipping Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkDark,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/checkout/address/add'),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          '+ Add New',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                addressesAsync.when(
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceWarm,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_off_outlined,
                                  size: 38,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No saved address found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Please add an address to proceed with checkout.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Auto-select first address if none selected
                    if (_selectedAddressId == null && addresses.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(
                            () => _selectedAddressId = addresses.first.id,
                          );
                        }
                      });
                    }

                    return Column(
                      children: addresses.map((address) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAddressCard(
                            address: address,
                            isSelected: _selectedAddressId == address.id,
                            onTap: () => setState(
                              () => _selectedAddressId = address.id,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (e, st) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Error: $e'),
                  ),
                ),

                const SizedBox(height: 8),

                // Add new address container
                InkWell(
                  onTap: () => context.push('/checkout/address/add'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 18,
                          color: AppColors.royalBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.royalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed Continue to Payment Button ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedAddressId == null
                      ? null
                      : () => context.push(
                            '/checkout/payment',
                            extra: _selectedAddressId,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required AddressModel address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.royalBlue
                : AppColors.border.withValues(alpha: 0.7),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.royalBlue.withValues(alpha: 0.08)
                  : const Color(0x06000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Icon
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.royalBlue : AppColors.textHint,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.royalBlue.withValues(alpha: 0.1)
                              : AppColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          address.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.royalBlue
                                : AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${address.street}, ${address.city}, ${address.state} - ${address.pincode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (address.phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      address.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isActive}) {
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
      color: isActive ? AppColors.royalBlue : const Color(0xFFE2E8F0),
    );
  }
}
