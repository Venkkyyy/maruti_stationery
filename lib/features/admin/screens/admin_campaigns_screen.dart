import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/campaign_model.dart';
import '../../../providers/storefront_provider.dart';
import '../../../providers/categories_provider.dart';

class AdminCampaignsScreen extends ConsumerStatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  ConsumerState<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends ConsumerState<AdminCampaignsScreen> {
  void _openCampaignSheet([CampaignModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final bannerCtrl = TextEditingController(text: existing?.bannerUrl ?? '');
    final badgeCtrl = TextEditingController(text: existing?.badgeText ?? '');
    DateTime startDate = existing?.startAt ?? DateTime.now();
    DateTime endDate = existing?.endAt ?? DateTime.now().add(const Duration(days: 14));
    String? selectedCollectionId = existing?.targetCollectionId;
    String? selectedCategoryId = existing?.targetCategoryId;
    bool isEnabled = existing?.isEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final collectionsAsync = ref.watch(productCollectionsStreamProvider);
            final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Create Marketing Campaign' : 'Edit Campaign',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.navyText,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Campaign Name
                    Text('Campaign Name *', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Back to School 2026',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    Text('Subtitle / Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Up to 40% off notebooks, pens & art supplies',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Badge Text
                    Text('Badge Tag (Optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: badgeCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. FLAT 30% OFF, LIMITED TIME',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Banner URL
                    Text('Banner Image URL', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bannerCtrl,
                      decoration: InputDecoration(
                        hintText: 'https://images.unsplash.com/...',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Date Pickers Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                label: Text(
                                  DateFormat('MMM dd, yyyy').format(startDate),
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.navyText),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => startDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.event_available_rounded, size: 16, color: AppColors.royalBlue),
                                label: Text(
                                  DateFormat('MMM dd, yyyy').format(endDate),
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.navyText),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => endDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Target Collection Link
                    Text('Link to Product Collection', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    collectionsAsync.maybeWhen(
                      data: (cols) {
                        return DropdownButtonFormField<String>(
                          value: cols.any((c) => c.id == selectedCollectionId) ? selectedCollectionId : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          hint: Text('Select Collection (Optional)', style: GoogleFonts.poppins(fontSize: 12)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None (General Campaign)')),
                            ...cols.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            setSheetState(() => selectedCollectionId = val);
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),

                    // Target Category Link
                    Text('Or Link to Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 6),
                    categoriesAsync.maybeWhen(
                      data: (cats) {
                        return DropdownButtonFormField<String>(
                          value: cats.any((c) => c.id == selectedCategoryId) ? selectedCategoryId : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          hint: Text('Select Category (Optional)', style: GoogleFonts.poppins(fontSize: 12)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            setSheetState(() => selectedCategoryId = val);
                          },
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),

                    // Enabled Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Campaign Active', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Controls whether this campaign displays across customer channels', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      value: isEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setSheetState(() => isEnabled = val),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a campaign name')),
                            );
                            return;
                          }

                          final now = DateTime.now();
                          final model = CampaignModel(
                            id: existing?.id ?? '',
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            bannerUrl: bannerCtrl.text.trim(),
                            badgeText: badgeCtrl.text.trim().isEmpty ? null : badgeCtrl.text.trim(),
                            targetCollectionId: selectedCollectionId,
                            targetCategoryId: selectedCategoryId,
                            startAt: startDate,
                            endAt: endDate,
                            isEnabled: isEnabled,
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                          );

                          await ref.read(storefrontServiceProvider).saveCampaign(model);
                          if (mounted) Navigator.pop(ctx);
                        },
                        child: Text(
                          existing == null ? 'Create Campaign' : 'Save Changes',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(activeCampaignsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyText,
        elevation: 0.5,
        title: Text(
          'Campaigns & Seasonal Events',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Campaign', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        onPressed: () => _openCampaignSheet(),
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 54, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No marketing campaigns yet',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.navyText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create seasonal sales, exam offers, or stationery holiday campaigns.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openCampaignSheet(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Create First Campaign', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = campaigns[index];
              final isLive = item.isCurrentlyLive;
              final isScheduled = DateTime.now().isBefore(item.startAt);
              final isEnded = DateTime.now().isAfter(item.endAt);

              Color statusBg = const Color(0xFFFEF3C7);
              Color statusColor = const Color(0xFFD97706);
              String statusLabel = 'Scheduled';

              if (!item.isEnabled) {
                statusBg = const Color(0xFFF1F5F9);
                statusColor = AppColors.textSecondary;
                statusLabel = 'Disabled';
              } else if (isLive) {
                statusBg = const Color(0xFFECFDF5);
                statusColor = const Color(0xFF059669);
                statusLabel = 'Live Now';
              } else if (isEnded) {
                statusBg = const Color(0xFFFEE2E2);
                statusColor = Colors.red;
                statusLabel = 'Ended';
              } else if (isScheduled) {
                statusBg = const Color(0xFFFEF3C7);
                statusColor = const Color(0xFFD97706);
                statusLabel = 'Scheduled';
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image if available
                    if (item.bannerUrl.isNotEmpty)
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: item.bannerUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFFFEDD5),
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              if (item.badgeText != null && item.badgeText!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Switch(
                                value: item.isEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  ref.read(storefrontServiceProvider).saveCampaign(
                                        item.copyWith(isEnabled: val),
                                      );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.navyText,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('MMM dd').format(item.startAt)} – ${DateFormat('MMM dd, yyyy').format(item.endAt)}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () async {
                                  final del = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete Campaign?'),
                                      content: Text('Are you sure you want to delete "${item.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (del == true) {
                                    ref.read(storefrontServiceProvider).deleteCampaign(item.id);
                                  }
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: AppColors.navyText,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                onPressed: () => _openCampaignSheet(item),
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
