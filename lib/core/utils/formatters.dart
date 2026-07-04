import 'package:intl/intl.dart';

/// Display formatters — for price, date, and other values.
class AppFormatters {
  AppFormatters._();

  static final _rupeeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _rupeeDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  // ── Price ──────────────────────────────────────────────────────────────────

  /// Format paise → "₹1,200"
  static String formatPrice(int paise) {
    return _rupeeFormat.format(paise / 100);
  }

  /// Format paise → "₹1,200.00"
  static String formatPriceDecimal(int paise) {
    return _rupeeDecimalFormat.format(paise / 100);
  }

  /// Format discount percentage → "25% OFF"
  static String formatDiscount(int mrp, int price) {
    if (mrp <= price || mrp == 0) return '';
    final percent = (((mrp - price) / mrp) * 100).round();
    return '$percent% OFF';
  }

  // ── Date / Time ────────────────────────────────────────────────────────────

  /// "30 Jun 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// "02:30 PM"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// "30 Jun 2026, 02:30 PM"
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Relative date — "Today", "Yesterday", or "28 Jun 2026"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _dateFormat.format(date);
  }

  // ── Quantity / Stock ────────────────────────────────────────────────────────

  /// "In Stock (42)" or "Low Stock (4)" or "Out of Stock"
  static String formatStock(int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock ($stock left)';
    return 'In Stock ($stock)';
  }

  // ── Phone ──────────────────────────────────────────────────────────────────

  /// "+919876543210" → "+91 98765 43210"
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final local = cleaned.substring(2);
      return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
    }
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return phone;
  }

  // ── Order ──────────────────────────────────────────────────────────────────

  /// "ORD-2026-783421" → "ORD-783421"
  static String formatOrderId(String orderId) {
    return orderId.length > 10 ? orderId.substring(orderId.length - 10) : orderId;
  }
}
