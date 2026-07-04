import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:maruti_stationery/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../../services/admin_product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductListScreen extends StatelessWidget {
  const AdminProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.primary,
        onPressed: () => context.go('/admin/products/add'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenHorizontal),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _AdminProductTile(product: product);
            },
          );
        },
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
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AdminProductService().deleteProduct(product.id, product.images);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50, height: 50,
            color: context.colors.surfaceGrey,
            child: product.images.isNotEmpty
                ? Image.network(product.images.first, fit: BoxFit.cover)
                : Icon(Icons.image_not_supported_rounded, color: context.colors.border),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${AppFormatters.formatPrice(product.price)} • Stock: ${product.stock}',
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: product.isActive,
              activeThumbColor: context.colors.primary,
              onChanged: (val) async {
                await AdminProductService().updateProduct(product.id, {'isActive': val});
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
              onPressed: () => _deleteProduct(context),
            ),
          ],
        ),
      ),
    );
  }
}






