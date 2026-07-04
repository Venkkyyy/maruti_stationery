import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDefault = false;

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
              _buildTextField(label: 'Full Name', hint: 'e.g. Vinikesh Hiranandani'),
              const SizedBox(height: 16),
              _buildTextField(label: 'Phone Number', hint: 'e.g. +91 98765 43210', keyboardType: TextInputType.phone),
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
              _buildTextField(label: 'Pincode', hint: 'e.g. 411001', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(label: 'Address (House No, Building, Street)', hint: 'e.g. Flat 402, Royal Residency', maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(label: 'City', hint: 'e.g. Pune')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(label: 'State', hint: 'e.g. Maharashtra')),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Address saved successfully!'),
                        backgroundColor: context.colors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    context.pop();
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
}






