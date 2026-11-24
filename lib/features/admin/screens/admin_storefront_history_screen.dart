import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/storefront_page_model.dart';
import '../../../models/storefront_section_model.dart';
import '../../../providers/storefront_provider.dart';

class AdminStorefrontHistoryScreen extends ConsumerStatefulWidget {
  const AdminStorefrontHistoryScreen({super.key});

  @override
  ConsumerState<AdminStorefrontHistoryScreen> createState() =>
      _AdminStorefrontHistoryScreenState();
}

class _AdminStorefrontHistoryScreenState
    extends ConsumerState<AdminStorefrontHistoryScreen> {
  bool _isRollingBack = false;

  Future<void> _handleRollback(StorefrontPageModel version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: Color(0xFFEA580C), size: 24),
            const SizedBox(width: 8),
            Text(
              'Rollback to v${version.version}?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to revert the storefront to the configuration published on ${DateFormat('MMM dd, yyyy – hh:mm a').format(version.publishedAt ?? DateTime.now())}?',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This snapshot contains ${version.sections.length} sections and will be published as the new active storefront version.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF9A3412),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Confirm Rollback',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRollingBack = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.email ?? user?.uid ?? 'admin';
      final service = ref.read(storefrontServiceProvider);

      await service.rollbackToVersion(
        pageId: 'home',
        historicalVersion: version,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reverted storefront to version ${version.version} snapshot!'),
            backgroundColor: const Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rollback failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRollingBack = false);
    }
  }

  void _showSectionsDetail(StorefrontPageModel version) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Snapshot v${version.version} Sections',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.navyText,
                        ),
                      ),
                      Text(
                        '${version.sections.length} Items',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: version.sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = version.sections[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title.isEmpty ? '(No Title)' : s.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.navyText,
                                    ),
                                  ),
                                  Text(
                                    '${StorefrontSectionType.getLabel(s.type)} • ${s.layoutVariant}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.isEnabled ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.isEnabled ? 'Active' : 'Disabled',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: s.isEnabled ? const Color(0xFF059669) : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(publishedStorefrontStreamProvider('home'));
    final historyAsync = ref.watch(storefrontVersionHistoryProvider('home'));

    final currentLiveVersion = liveAsync.value?.version ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyText,
        elevation: 0.5,
        title: Text(
          'Version History & Rollback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _isRollingBack
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Rolling back storefront version...'),
                ],
              ),
            )
          : historyAsync.when(
              data: (historyList) {
                if (historyList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 54, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No published versions recorded yet',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.navyText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Publishing from the Home Screen Builder creates immutable version snapshots here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    final isCurrent = item.version == currentLiveVersion;
                    final dateStr = item.publishedAt != null
                        ? DateFormat('MMM dd, yyyy • hh:mm a').format(item.publishedAt!)
                        : 'Unknown Date';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : AppColors.border,
                          width: isCurrent ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'v${item.version}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isCurrent ? Colors.white : AppColors.navyText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ACTIVE LIVE',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                '${item.sections.length} Sections',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.royalBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            (item.changeSummary == null || item.changeSummary!.isEmpty)
                                ? 'Storefront snapshot release v${item.version}'
                                : item.changeSummary!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.navyText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.publishedBy ?? 'admin',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navyText,
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () => _showSectionsDetail(item),
                                icon: const Icon(Icons.list_alt_rounded, size: 16),
                                label: Text(
                                  'View Sections',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isCurrent)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEA580C),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _handleRollback(item),
                                  icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
                                  label: Text(
                                    'Rollback to v${item.version}',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text('Error loading history: $err'),
              ),
            ),
    );
  }
}
