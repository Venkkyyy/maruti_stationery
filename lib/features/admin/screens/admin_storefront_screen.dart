import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/storefront_provider.dart';

class AdminStorefrontScreen extends ConsumerWidget {
  const AdminStorefrontScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publishedAsync = ref.watch(publishedStorefrontStreamProvider('home'));
    final draftAsync = ref.watch(draftStorefrontStreamProvider('home'));
    final collectionsAsync = ref.watch(productCollectionsStreamProvider);
    final historyAsync = ref.watch(storefrontVersionHistoryProvider('home'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Storefront Management (SDUI)',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.navyText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Live Device Preview',
            icon: const Icon(Icons.phone_iphone_rounded, color: AppColors.royalBlue),
            onPressed: () => context.push('/admin/storefront/preview'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. LIVE STOREFRONT STATUS BANNER ────────────────────────────
            publishedAsync.when(
              data: (page) {
                final dateStr = page.publishedAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(page.publishedAt!)
                    : 'Initial release';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.cloud_done_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Storefront v${page.version}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.navyText,
                                    ),
                                  ),
                                  Text(
                                    'Published: $dateStr',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${page.sections.length} Sections',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.royalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (page.changeSummary != null && page.changeSummary!.isNotEmpty) ...[
                        const Divider(height: 20),
                        Text(
                          'Note: ${page.changeSummary}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // ── 2. MODULE NAVIGATION TILES ──────────────────────────────────
            Text(
              'Storefront Modules',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.navyText,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildModuleCard(
                  context: context,
                  title: 'Home Screen Builder',
                  subtitle: 'Drag & drop sections, configure layouts',
                  icon: Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push('/admin/home-layout'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Product Collections',
                  subtitle: 'Trending, Curated & Rules',
                  icon: Icons.auto_awesome_motion_rounded,
                  color: AppColors.royalBlue,
                  badgeText: '${collectionsAsync.value?.length ?? 5} Active',
                  onTap: () => context.push('/admin/storefront/collections'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Banners & Promotions',
                  subtitle: 'Carousel sliders & offers',
                  icon: Icons.view_carousel_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () => context.push('/admin/banners'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Live Device Preview',
                  subtitle: 'Interactive customer screen preview',
                  icon: Icons.phone_iphone_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () => context.push('/admin/storefront/preview'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Version History',
                  subtitle: 'Rollback & snapshots',
                  icon: Icons.history_rounded,
                  color: const Color(0xFFEA580C),
                  badgeText: '${historyAsync.value?.length ?? 1} Saved',
                  onTap: () => context.push('/admin/storefront/history'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Seasonal Campaigns',
                  subtitle: 'Timed sales & promotional events',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => context.push('/admin/storefront/campaigns'),
                ),
                _buildModuleCard(
                  context: context,
                  title: 'Content Policies CMS',
                  subtitle: 'About, Returns, Announcement',
                  icon: Icons.article_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: () => context.push('/admin/cms'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 3. DRAFT STAGING STATUS ─────────────────────────────────────
            draftAsync.when(
              data: (draft) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staged Draft Canvas',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.navyText,
                              ),
                            ),
                            Text(
                              '${draft.sections.length} sections staged for next release',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.push('/admin/home-layout'),
                        child: Text(
                          'Open Builder',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarm,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.navyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
