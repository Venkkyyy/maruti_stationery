import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/address_model.dart';
import '../../../providers/address_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  bool _isDefault = false;
  String _addressType = 'Home';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }


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
          'Add Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(label: 'Full Name', hint: 'e.g. Vinikesh Hiranandani', controller: _nameController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Phone Number', hint: 'e.g. +91 98765 43210', keyboardType: TextInputType.phone, controller: _phoneController),
              const SizedBox(height: 32),
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(label: 'Pincode', hint: 'e.g. 411001', keyboardType: TextInputType.number, controller: _pincodeController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Address (House No, Building, Street)', hint: 'e.g. Flat 402, Royal Residency', maxLines: 2, controller: _streetController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: 'City', hint: 'e.g. Pune', controller: _cityController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(label: 'State', hint: 'e.g. Maharashtra', controller: _stateController)),
                ],
              ),
              const SizedBox(height: 24),
              // Address Type Selector
              Row(
                children: [
                  _buildTypeChip('Home'),
                  const SizedBox(width: 12),
                  _buildTypeChip('Office'),
                  const SizedBox(width: 12),
                  _buildTypeChip('Other'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val),
                    activeThumbColor: context.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Use as default address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Address',
                isLoading: _isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      final newAddress = AddressModel(
                        id: '', // Generated by Firestore
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        street: _streetController.text.trim(),
                        city: _cityController.text.trim(),
                        state: _stateController.text.trim(),
                        pincode: _pincodeController.text.trim(),
                        type: _addressType,
                      );

                      await ref.read(addressProvider.notifier).addAddress(newAddress);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Address saved successfully!'),
                          backgroundColor: context.colors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      context.pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: context.colors.error),
                      );
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.colors.primary),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label) {
    final isSelected = _addressType == label;
    return GestureDetector(
      onTap: () => setState(() => _addressType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryLight : context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? context.colors.primary : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}






