import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/banner_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(allBannersProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Manage Banners'),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.primary),
            onPressed: () => context.push('/admin/banners/add'),
          ),
        ],
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(child: Text('No banners found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: context.colors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    if (banner.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            banner.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: banner.isActive ? Colors.green : context.colors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: banner.isActive,
                            activeColor: context.colors.primary,
                            onChanged: (value) async {
                              await FirebaseFirestore.instance
                                  .collection('banners')
                                  .doc(banner.id)
                                  .update({'isActive': value});
                            },
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: context.colors.primary),
                                onPressed: () => context.push('/admin/banners/edit/${banner.id}', extra: banner),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Banner?'),
                                      content: const Text('Are you sure you want to delete this banner?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('banners')
                                        .doc(banner.id)
                                        .delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
