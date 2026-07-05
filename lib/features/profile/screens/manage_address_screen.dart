import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  int _selectedAddress = 0;

  final List<_Address> _addresses = [
    _Address(
      id: 0,
      label: 'Home',
      name: 'Vinikesh Hiranandani',
      address: 'Flat 402, Royal Residency,\nKoregaon Park, Pune - 411001',
      phone: '+91 98765 43210',
    ),
    _Address(
      id: 1,
      label: 'Office',
      name: 'Vinikesh Hiranandani',
      address: '12th Floor, Cyber Towers,\nHinjewadi Phase 2, Pune - 411057',
      phone: '+91 98765 43210',
    ),
  ];

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
                ..._addresses.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddressCard(
                        address: e.value,
                        isSelected: _selectedAddress == e.key,
                        onTap: () => setState(() => _selectedAddress = e.key),
                      ),
                    )),

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

class _Address {
  final int id;
  final String label;
  final String name;
  final String address;
  final String phone;

  const _Address({
    required this.id,
    required this.label,
    required this.name,
    required this.address,
    required this.phone,
  });
}

class _AddressCard extends StatelessWidget {
  final _Address address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
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
                          address.label.toUpperCase(),
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
                      Text(
                        address.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
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








