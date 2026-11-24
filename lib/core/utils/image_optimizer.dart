class ImageOptimizer {
  ImageOptimizer._();

  /// Transforms image URLs (Cloudinary, Unsplash, etc.) into optimized thumbnails
  /// reducing payload from ~2-4MB down to ~30-50KB.
  static String getThumbnailUrl(
    String originalUrl, {
    int width = 360,
    int height = 360,
    int quality = 80,
    String crop = 'limit', // 'limit' or 'fill'
  }) {
    if (originalUrl.isEmpty) return originalUrl;

    // 1. Cloudinary Optimization
    if (originalUrl.contains('res.cloudinary.com')) {
      const uploadAnchor = '/image/upload/';
      if (originalUrl.contains(uploadAnchor)) {
        // e.g. https://res.cloudinary.com/eizhyg2w/image/upload/v1788/item.jpg
        // Insert: /image/upload/c_limit,w_360,h_360,q_auto,f_auto/v1788/item.jpg
        final transformation = 'c_$crop,w_$width,h_$height,q_auto,f_auto/';
        return originalUrl.replaceFirst(uploadAnchor, '$uploadAnchor$transformation');
      }
    }

    // 2. Unsplash Optimization
    if (originalUrl.contains('images.unsplash.com')) {
      final uri = Uri.parse(originalUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['w'] = width.toString();
      queryParams['q'] = quality.toString();
      queryParams['auto'] = 'format';
      return uri.replace(queryParameters: queryParams).toString();
    }

    // Default fallback
    return originalUrl;
  }

  /// High-resolution banner optimization (e.g. for hero carousels)
  static String getBannerUrl(
    String originalUrl, {
    int width = 1080,
    int quality = 85,
  }) {
    return getThumbnailUrl(originalUrl, width: width, height: 480, quality: quality, crop: 'limit');
  }
}

