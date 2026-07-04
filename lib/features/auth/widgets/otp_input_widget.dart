import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_sizes.dart';

/// Reusable 6-box OTP input widget.
/// Exposes [onCompleted] when all 6 digits are entered.
class OtpInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpInputWidget({
    super.key,
    this.length = AppSizes.otpLength,
    this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    widget.onChanged?.call(_currentOtp);
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_currentOtp.length == widget.length) {
      widget.onCompleted?.call(_currentOtp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Called from parent to reset fields
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (i) => _OtpBox(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          onChanged: (val) => _onDigitEntered(i, val),
          onKeyEvent: (event) => _onKeyEvent(i, event),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.otpBoxWidth,
      height: AppSizes.otpBoxHeight,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: context.colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: BorderSide(color: context.colors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}






