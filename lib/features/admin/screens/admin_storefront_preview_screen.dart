import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/storefront_provider.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/ads_provider.dart';
import '../../../providers/brand_provider.dart';
import '../../../models/storefront_page_model.dart';
import '../../../shared/sdui/storefront_section_renderer.dart';

class AdminStorefrontPreviewScreen extends ConsumerStatefulWidget {
  const AdminStorefrontPreviewScreen({super.key});

  @override
  ConsumerState<AdminStorefrontPreviewScreen> createState() =>
      _AdminStorefrontPreviewScreenState();
}

class _AdminStorefrontPreviewScreenState
    extends ConsumerState<AdminStorefrontPreviewScreen> {
  bool _previewPublished = false;
  double _frameWidth = 390; // Standard modern mobile width
  bool _isPublishing = false;

  Future<void> _handlePublish(StorefrontPageModel page) async {
    final summaryController = TextEditingController(
      text: 'Update storefront layout (${page.sections.length} sections)',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Publish to Customers',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will immediately update the customer home screen without requiring an app update.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'Release Note / Change Summary:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: summaryController,
              decoration: InputDecoration(
                hintText: 'e.g. Back to school collection update',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Publish Now', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPublishing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.email ?? user?.uid ?? 'admin';
      final service = ref.read(storefrontServiceProvider);

      await service.publishDraft(
        pageId: 'home',
        userId: userId,
        changeSummary: summaryController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Storefront published successfully to customer apps!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publishing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = _previewPublished
        ? ref.watch(publishedStorefrontStreamProvider('home'))
        : ref.watch(draftStorefrontStreamProvider('home'));

    final banners = ref.watch(bannerProvider).value ?? [];
    final categories = ref.watch(activeCategoriesStreamProvider).value ?? [];
    final allProducts = ref.watch(activeProductsStreamProvider('all')).value ?? [];
    final ads = ref.watch(activeAdsProvider).value ?? [];
    final brands = ref.watch(watchBrandsProvider).value ?? [];
    final collections = ref.watch(productCollectionsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark slate canvas to highlight device
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Device Preview',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              _previewPublished ? 'Viewing Live Published Feed' : 'Viewing Staged Draft',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _previewPublished ? const Color(0xFF34D399) : AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Draft in Builder',
            icon: const Icon(Icons.dashboard_customize_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/home-layout'),
          ),
          pageAsync.maybeWhen(
            data: (page) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _isPublishing ? null : () => _handlePublish(page),
                icon: _isPublishing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.rocket_launch_rounded, size: 16),
                label: Text(
                  'Publish',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── TOP CONTROLS BAR ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                // Mode Toggle (Draft vs Published)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildModeChip(
                        label: 'Draft Canvas',
                        isSelected: !_previewPublished,
                        onTap: () => setState(() => _previewPublished = false),
                      ),
                      _buildModeChip(
                        label: 'Live Published',
                        isSelected: _previewPublished,
                        onTap: () => setState(() => _previewPublished = true),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Device Width Switcher
                IconButton(
                  tooltip: 'Compact (360px)',
                  icon: Icon(
                    Icons.phone_android_rounded,
                    color: _frameWidth == 360 ? AppColors.primary : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _frameWidth = 360),
                ),
                IconButton(
                  tooltip: 'Standard (390px)',
                  icon: Icon(
                    Icons.phone_iphone_rounded,
                    color: _frameWidth == 390 ? AppColors.primary : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _frameWidth = 390),
                ),
                IconButton(
                  tooltip: 'Wide (430px)',
                  icon: Icon(
                    Icons.tablet_mac_rounded,
                    color: _frameWidth == 430 ? AppColors.primary : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _frameWidth = 430),
                ),
              ],
            ),
          ),

          // ── SIMULATED DEVICE FRAME ────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: _frameWidth,
                  height: 780,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(44),
                    border: Border.all(color: const Color(0xFF334155), width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Scrollable Screen Content
                      pageAsync.when(
                        data: (page) {
                          final visibleSections = page.sections
                              .where((s) => s.isEnabled && s.isCurrentlyScheduledActive)
                              .toList();

                          if (visibleSections.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.layers_clear_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No active sections to render',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              // Simulated Top Spacing for Notch
                              const SliverToBoxAdapter(child: SizedBox(height: 48)),

                              // Render SDUI Sections
                              ...visibleSections.map(
                                (section) => SliverToBoxAdapter(
                                  child: StorefrontSectionRenderer(
                                    section: section,
                                    allProducts: allProducts,
                                    categories: categories,
                                    banners: banners,
                                    ads: ads,
                                    brands: brands,
                                    collections: collections,
                                    loggedImpressions: const {},
                                  ),
                                ),
                              ),

                              const SliverToBoxAdapter(child: SizedBox(height: 80)),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Error loading preview: $err',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                      ),

                      // Simulated Top Notch & Status Bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: AppColors.background.withValues(alpha: 0.95),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '9:41',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.navyText,
                                ),
                              ),
                              // Dynamic Island / Notch
                              Container(
                                width: 90,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.signal_cellular_alt_rounded, size: 14, color: AppColors.navyText),
                                  SizedBox(width: 4),
                                  Icon(Icons.wifi_rounded, size: 14, color: AppColors.navyText),
                                  SizedBox(width: 4),
                                  Icon(Icons.battery_full_rounded, size: 16, color: AppColors.navyText),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Simulated Home Indicator Line
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 130,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
