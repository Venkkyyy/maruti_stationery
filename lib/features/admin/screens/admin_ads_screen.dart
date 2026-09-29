import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ad_model.dart';
import '../../../providers/ads_provider.dart';
import 'package:intl/intl.dart';

class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(allAdsProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Video Ads'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/ads/add'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Ad', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ads) {
          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_display_outlined,
                      size: 72, color: colors.border),
                  const SizedBox(height: 16),
                  Text(
                    'No video ads yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + New Ad to create your first campaign.',
                    style: TextStyle(fontSize: 14, color: colors.textHint),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ads.length,
            itemBuilder: (context, i) => _AdListTile(
              ad: ads[i],
              onEdit: () => context.push('/admin/ads/edit/${ads[i].id}',
                  extra: ads[i]),
              onDelete: () => _confirmDelete(context, ads[i].id),
              onToggle: (val) => toggleAdActive(ads[i].id, val),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String adId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text(
            'This ad will be removed from the customer feed immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteAd(adId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AdListTile extends StatelessWidget {
  final AdModel ad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _AdListTile({
    required this.ad,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail preview
          if (ad.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                        imageUrl: ad.thumbnailUrl, fit: BoxFit.cover),
                    // Play icon overlay
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100,
                color: colors.surfaceGrey,
                child: Center(
                  child: Icon(Icons.smart_display_outlined,
                      size: 48, color: colors.textHint),
                ),
              ),
            ),

          // Info + controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + toggle row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ad.isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : colors.surfaceGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ad.isActive ? 'ACTIVE' : 'PAUSED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ad.isActive
                              ? Colors.green.shade700
                              : colors.textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: ad.isActive,
                      onChanged: onToggle,
                      activeThumbColor: colors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Placement freq + sort order
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.repeat_rounded,
                      label: 'Every ${ad.placementFrequency} products',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.sort_rounded,
                      label: 'Priority ${ad.sortOrder}',
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date range
                if (ad.startDate != null || ad.endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            size: 14, color: colors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          [
                            if (ad.startDate != null)
                              'From ${fmt.format(ad.startDate!)}',
                            if (ad.endDate != null)
                              'Until ${fmt.format(ad.endDate!)}',
                          ].join(' '),
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                // Stats
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.visibility_outlined,
                      value: _fmt(ad.impressions),
                      label: 'Impressions',
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatBadge(
                      icon: Icons.ads_click_rounded,
                      value: _fmt(ad.clicks),
                      label: 'Clicks',
                      color: Colors.orange,
                    ),
                    if (ad.impressions > 0) ...[
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.percent_rounded,
                        value:
                            '${((ad.clicks / ad.impressions) * 100).toStringAsFixed(1)}%',
                        label: 'CTR',
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Edit / Delete buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon:
                            Icon(Icons.edit_outlined, size: 16, color: colors.primary),
                        label: Text('Edit',
                            style: TextStyle(color: colors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: Colors.red),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatBadge(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
