/// Form validators — all return null on success, error string on failure.
class Validators {
  Validators._();

  /// 10-digit Indian mobile number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) return 'Enter a valid 10-digit number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  /// 6-digit OTP
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP must contain only digits';
    return null;
  }

  /// Required text field
  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  /// Product name
  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Product name is required';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (value.trim().length > 200) return 'Name must be under 200 characters';
    return null;
  }

  /// Price — expects rupees as string, converts to paise
  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid price';
    if (parsed <= 0) return 'Price must be greater than 0';
    if (parsed > 1000000) return 'Price seems too high';
    return null;
  }

  /// Stock quantity
  static String? stock(String? value) {
    if (value == null || value.isEmpty) return 'Stock is required';
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Enter a valid quantity';
    if (parsed < 0) return 'Stock cannot be negative';
    return null;
  }

  /// Pincode — 6 digits
  static String? pincode(String? value) {
    if (value == null || value.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter a valid 6-digit pincode';
    return null;
  }

  /// Full name
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  /// Email (optional)
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }
}
