import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class AdminProductCategoriesScreen extends StatefulWidget {
  const AdminProductCategoriesScreen({super.key});

  @override
  State<AdminProductCategoriesScreen> createState() => _AdminProductCategoriesScreenState();
}

class _AdminProductCategoriesScreenState extends State<AdminProductCategoriesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Product Categories',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/products/bulk-upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.table_view_rounded, size: 18),
              label: Text(
                'Bulk Import',
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Bulk Upload Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Bulk Upload Card Shortcut
                InkWell(
                  onTap: () => context.push('/admin/products/bulk-upload'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalBlue.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bulk Upload via Excel / CSV',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.navyText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add dozens or hundreds of products at once with our sample template',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.royalBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No categories found.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  );
                }

                var categories = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((doc) {
                    final name = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
                    return name.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (categories.isEmpty) {
                  return Center(
                    child: Text('No matching categories found.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length + (_searchQuery.isEmpty ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (_searchQuery.isEmpty && index == 0) {
                      // All Products Header Card
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.navyText, Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x15000000), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.all_inbox_rounded, color: Colors.white, size: 24),
                          ),
                          title: Text(
                            'All Products',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'View, filter and edit all inventory items',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                          onTap: () {
                            context.push('/admin/products/category/all', extra: 'All');
                          },
                        ),
                      );
                    }

                    final categoryDoc = categories[_searchQuery.isEmpty ? index - 1 : index];
                    final data = categoryDoc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final imageUrl = data['image'] ?? data['imageUrl'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.category_rounded, color: AppColors.royalBlue),
                                  ),
                                )
                              : const Icon(Icons.category_rounded, color: AppColors.royalBlue),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyText,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                        onTap: () {
                          context.push('/admin/products/category/${categoryDoc.id}', extra: name);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
