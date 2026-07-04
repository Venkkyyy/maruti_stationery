import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_sizes.dart';

/// A styled text field used across the app for consistency.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          autofocus: autofocus,
          style: TextStyle(
            fontSize: 15,
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.colors.textHint,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            counterText: '',
            filled: true,
            fillColor: context.colors.background,
            prefixIcon: prefix,
            suffixIcon: suffix,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              borderSide: BorderSide(color: context.colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              borderSide: BorderSide(color: context.colors.error, width: 1.5),
            ),
            errorStyle: TextStyle(
              color: context.colors.error,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}






