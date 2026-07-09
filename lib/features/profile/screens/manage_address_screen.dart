import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/address_model.dart';
import '../../../providers/address_provider.dart';

class ManageAddressScreen extends ConsumerStatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  ConsumerState<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends ConsumerState<ManageAddressScreen> {
  String? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Saved Addresses',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ref.watch(addressProvider).when(
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No saved addresses. Please add one.',
                          style: TextStyle(color: context.colors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: addresses.map((address) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AddressCard(
                            address: address,
                            isSelected: _selectedAddressId == address.id,
                            onTap: () => setState(() => _selectedAddressId = address.id),
                            onDelete: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: context.colors.surface,
                                  title: Text('Delete Address', style: TextStyle(color: context.colors.textPrimary)),
                                  content: Text('Are you sure you want to delete this address?', style: TextStyle(color: context.colors.textSecondary)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => context.pop(),
                                      child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ref.read(addressProvider.notifier).removeAddress(address.id);
                                        context.pop();
                                      },
                                      child: Text('Delete', style: TextStyle(color: context.colors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => Text('Error: $e'),
                ),

                // Add new address
                GestureDetector(
                  onTap: () => context.push('/checkout/address/add'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: 0.4),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: context.colors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? context.colors.primary : context.colors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: context.colors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.primaryLight
                              : context.colors.surfaceGrey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          address.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.delete_outline_rounded, color: context.colors.error, size: 20),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.street}, ${address.city}, ${address.state} - ${address.pincode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address.phone,
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textHint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}








