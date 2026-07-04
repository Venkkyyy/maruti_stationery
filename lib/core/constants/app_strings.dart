/// All hardcoded user-facing strings in one place.
/// Replace values with localization keys when adding multi-language support.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Maruti Stationery';
  static const String appTagline = 'Premium Writing Instruments';

  // Auth
  static const String enterMobile = 'Enter your\nmobile number';
  static const String mobileSubtitle =
      "We'll send a 6-digit OTP to verify your number.";
  static const String sendOtp = 'Send OTP';
  static const String verifyNumber = 'Verify your\nnumber';
  static const String enterOtp = 'Enter the 6-digit OTP sent to your mobile number.';
  static const String verifyProceed = 'Verify & Proceed';
  static const String resendOtpIn = 'Resend OTP in ';
  static const String resendOtp = 'Resend OTP';
  static const String termsPrefix = 'By continuing, you agree to our ';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String and = ' & ';

  // Onboarding
  static const String signatureCollection = 'SIGNATURE COLLECTION';
  static const String onboardingTitle = 'Elevate Your\nWriting Experience';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';

  // Home
  static const String searchHint = 'Search catalogs, products...';
  static const String newArrivals = 'New Arrivals';
  static const String viewAll = 'View all';
  static const String shopNow = 'Shop Now';
  static const String heroTitle = 'Elevate Your Desk\nExperience';

  // Catalog
  static const String productCatalog = 'Product Catalog';
  static const String searchSkuHint = 'Search SKU, Product Name...';
  static const String allCategories = 'All Categories';
  static const String loadMore = 'Load More Products';
  static const String outOfStock = 'OUT OF STOCK';
  static const String lowStock = 'Low Stock';

  // Product Detail
  static const String inStock = 'In Stock';
  static const String addToBag = 'Add to Bag';
  static const String addingToBag = 'Adding...';
  static const String productDescription = 'Product Description';
  static const String specifications = 'Specifications';
  static const String outOfStockMessage =
      'Currently Out of Stock. Contact us for availability.';
  static const String shopPhone = '+91 98765 43210';

  // Cart
  static const String shoppingBag = 'Shopping Bag';
  static const String promoPlaceholder = 'Enter promo code';
  static const String apply = 'Apply';
  static const String applied = '✓ Applied';
  static const String billSummary = 'Bill Summary';
  static const String itemsTotal = 'Items Total';
  static const String deliveryCharges = 'Delivery Charges';
  static const String deliveryFree = 'Free';
  static const String promoDiscount = 'Promo Discount';
  static const String grandTotal = 'Grand Total';
  static const String proceedToCheckout = 'Proceed to Checkout';
  static const String emptyBag = 'Your bag is empty';
  static const String emptyBagSub = 'Add items to get started';
  static const String browseCatalog = 'Browse Catalog';

  // Checkout
  static const String deliveryAddress = 'Delivery Address';
  static const String savedAddresses = 'Saved Addresses';
  static const String addNewAddress = 'Add New Address';
  static const String continuePayment = 'Continue to Payment';
  static const String payment = 'Payment';
  static const String orderSummary = 'Order Summary';
  static const String selectPayment = 'Select Payment Method';
  static const String securePayment = '100% Secure Payments via Razorpay';
  static const String placeOrder = 'Place Order';
  static const String orderPlaced = 'Order Placed! 🎉';
  static const String orderPlacedSub =
      'Thank you for shopping with Maruti Stationery.\nYour premium items are on their way!';
  static const String orderId = 'ORDER ID';
  static const String trackOrder = 'Track Order';
  static const String continueShopping = 'Continue Shopping';

  // Orders
  static const String myOrders = 'My Orders';
  static const String orderTracking = 'Order Tracking';
  static const String liveTracking = 'Live Tracking';
  static const String itemsInOrder = 'Items in this Order';
  static const String deliveryAddressLabel = 'Delivery Address';
  static const String buyAgain = 'Buy Again';

  // Profile
  static const String myAccount = 'My Account';
  static const String support = 'Support';
  static const String logOut = 'Log Out';
  static const String orders = 'Orders';
  static const String wishlist = 'Wishlist';
  static const String addresses = 'Addresses';

  // Wishlist
  static const String myWishlist = 'My Wishlist';
  static const String emptyWishlist = 'Your wishlist is empty';
  static const String emptyWishlistSub = 'Save items you love to buy later';

  // Search
  static const String search = 'Search';
  static const String searchProducts = 'Search products, brands, SKUs...';
  static const String noResults = 'No results found';
  static const String noResultsSub = 'Try different keywords';

  // Errors
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgain = 'Try Again';
  static const String noInternet = 'No internet connection';
  static const String sessionExpired = 'Session expired. Please login again.';
  static const String invalidPhone = 'Please enter a valid 10-digit mobile number';
  static const String invalidOtp = 'Please enter the 6-digit OTP';
}
