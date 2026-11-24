import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../services/admin_product_service.dart';

class AdminProductListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const AdminProductListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  String _searchQuery = '';
  String _filterType = 'All'; // 'All', 'In Stock', 'Out of Stock', 'Photo Pending'

  @override
  Widget build(BuildContext context) {
    final isAll = widget.categoryId == 'all';
    final displayName = isAll ? 'All' : widget.categoryName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '$displayName Products',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Bulk Products & Photos Upload',
            icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.royalBlue),
            onPressed: () => context.push('/admin/products/bulk-upload'),
          ),
          IconButton(
            tooltip: 'Add Single Product',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => context.push('/admin/products/add', extra: isAll ? null : widget.categoryId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => context.push('/admin/products/add', extra: isAll ? null : widget.categoryId),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products by name or brand...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                    filled: true,
                    fillColor: AppColors.surfaceWarm,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Quick Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Photo Pending'),
                      _buildFilterChip('In Stock'),
                      _buildFilterChip('Out of Stock'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: isAll
                  ? FirebaseFirestore.instance.collection('products').snapshots()
                  : FirebaseFirestore.instance
                      .collection('products')
                      .where('categoryId', isEqualTo: widget.categoryId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No products found in this category.',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/admin/products/add', extra: isAll ? null : widget.categoryId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text('Add First Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var products = snapshot.data!.docs
                    .map((doc) => ProductModel.fromFirestore(doc))
                    .toList();

                // Sort newest first
                products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                // Filter by type
                if (_filterType == 'Photo Pending') {
                  products = products.where((p) => p.images.isEmpty).toList();
                } else if (_filterType == 'In Stock') {
                  products = products.where((p) => p.stock > 0).toList();
                } else if (_filterType == 'Out of Stock') {
                  products = products.where((p) => p.stock <= 0).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.brand.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint.withValues(alpha: 0.6)),
                        const SizedBox(height: 10),
                        Text(
                          'No matching products found.',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _AdminProductTile(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterType = label),
        backgroundColor: AppColors.surfaceWarm,
        selectedColor: label == 'Photo Pending' ? AppColors.primary : AppColors.royalBlue,
        labelStyle: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.navyText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductModel product;

  const _AdminProductTile({required this.product});

  Future<void> _deleteProduct(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText)),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AdminProductService().deleteProduct(
        product.id,
        product.images,
        deleteTokens: product.imageDeleteTokens,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} deleted'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = product.images.isNotEmpty;
    final isOutOfStock = product.stock <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: !hasImages
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail or "Photo Pending" badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImages
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.surfaceWarm),
                        errorWidget: (context, url, error) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.surfaceWarm,
                          child: const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.primary.withValues(alpha: 0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 24),
                            const SizedBox(height: 2),
                            Text(
                              'Add Photo',
                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
              ),
              if (isOutOfStock)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OOS',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.navyText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.brand}  •  Stock: ${product.stock} ${product.unit}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: isOutOfStock ? AppColors.error : AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      AppFormatters.formatPrice(product.price),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    if (product.mrp > product.price) ...[
                      const SizedBox(width: 6),
                      Text(
                        AppFormatters.formatPrice(product.mrp),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!hasImages)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Photo Pending',
                          style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'edit') {
                context.push('/admin/products/edit/${product.id}');
              } else if (val == 'delete') {
                _deleteProduct(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(hasImages ? Icons.edit_rounded : Icons.add_a_photo_rounded, size: 18, color: AppColors.royalBlue),
                    const SizedBox(width: 10),
                    Text(hasImages ? 'Edit Product' : 'Attach Photo & Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text('Delete', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
