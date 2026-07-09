import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Select Category'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: false, // Managed by ShellRoute if root tab
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                }

                var categories = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  categories = categories.where((doc) {
                    final name = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
                    return name.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (categories.isEmpty) {
                  return const Center(child: Text('No matching categories found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final categoryDoc = categories[index];
                    final data = categoryDoc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final imageUrl = data['imageUrl'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: context.colors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(imageUrl, fit: BoxFit.cover),
                                )
                              : Icon(Icons.category_rounded, color: context.colors.primary),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
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
