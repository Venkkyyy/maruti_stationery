import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  
  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;

  void initialize() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  Future<void> openCheckout({
    required String razorpayOrderId,
    required int amount,
    required String userName,
    required String userPhone,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
  }) async {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;

    final options = {
      'key': 'rzp_live_YOUR_KEY_ID',   // This is the PUBLIC key — safe in Flutter
      'order_id': razorpayOrderId,
      'amount': amount,
      'name': 'Maruti Stationery',
      'description': 'Order Payment',
      'prefill': {
        'name': userName,
        'contact': userPhone,
      },
      'theme': {'color': '#FF3F6C'}, // Custom pink brand color
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onFailure?.call(PaymentFailureResponse(0, e.toString(), null));
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void dispose() {
    _razorpay.clear();
  }
}
