import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/privacy_service.dart';

class PrivacyCenterScreen extends ConsumerStatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  ConsumerState<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends ConsumerState<PrivacyCenterScreen> {
  final PrivacyService _privacyService = PrivacyService();
  bool _isExporting = false;
  bool _isDeleting = false;

  // Preferences
  bool _promoEmailConsent = true;
  bool _promoPushConsent = false;
  bool _personalizedAdsConsent = true;

  Future<void> _handleDataExport(String userId) async {
    setState(() => _isExporting = true);
    try {
      final exportData = await _privacyService.exportUserData(userId);
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      await Share.share(
        jsonString,
        subject: 'My Maruti Stationery Data Export (${DateFormat('dd-MMM-yyyy').format(DateTime.now())})',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Personal data export generated successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showCorrectionDialog(String userId, String userEmail) {
    final detailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Request Data Correction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Under the DPDP Act 2023, you have the right to request correction of inaccurate or incomplete personal data.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailCtrl,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe the incorrect information and the requested update...',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (detailCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _privacyService.submitCorrectionRequest(
                userId: userId,
                userEmail: userEmail,
                details: detailCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correction request submitted to Data Protection Officer.'),
                    backgroundColor: Color(0xFF0D9488),
                  ),
                );
              }
            },
            child: Text('Submit Request', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountWorkflow(String userId) {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Delete Account & Data',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What will be deleted:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Your personal profile, email, phone, and saved addresses\n'
                    '• All items in your shopping cart and wishlist\n'
                    '• Your push notification device tokens\n'
                    '• Your accumulated loyalty points balance',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What is legally retained:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Past order tax receipts and financial invoices (anonymized per Indian GST statutory audit requirements for 7 years).',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      'Type "DELETE" to confirm permanent account deletion:',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: confirmCtrl.text.trim() != 'DELETE' || _isDeleting
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        setState(() => _isDeleting = true);
                        try {
                          await _privacyService.processAccountDeletion(userId: userId);
                          if (mounted) {
                            context.go('/onboarding');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isDeleting = false);
                        }
                      },
                child: Text('Permanently Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navyText,
        elevation: 0.5,
        title: Text(
          'Privacy & Data Protection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // ── 1. PERSONAL DATA CARD ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.royalBlue, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Your Identity & Contact',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/profile/edit'),
                            child: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Full Name', user.name.isEmpty ? 'Not set' : user.name),
                      _buildInfoRow('Email Address', user.email ?? 'Not linked'),
                      _buildInfoRow('Phone Number', user.phone.isEmpty ? 'Not set' : user.phone),
                      _buildInfoRow('Account Created', DateFormat('MMM dd, yyyy').format(user.createdAt)),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 2. CONSENT & COMMUNICATION PREFERENCES ───────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Communication & Marketing Preferences',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText),
                      ),
                      Text(
                        'Control how Maruti Stationery contacts you under DPDP Act 2023.',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Transactional Updates', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Order confirmations, tracking & security notices (Mandatory)', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        value: true,
                        activeColor: AppColors.primary,
                        onChanged: null, // Disabled: transactional is essential
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Promotional Emails', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Exclusive stationery sales & coupon codes', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        value: _promoEmailConsent,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _promoEmailConsent = val);
                          _privacyService.recordConsent(userId: user.id, consentType: 'promotional_email', granted: val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Promotional Push Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Alerts on flash sales and restocked items', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        value: _promoPushConsent,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _promoPushConsent = val);
                          _privacyService.recordConsent(userId: user.id, consentType: 'promotional_push', granted: val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 3. DATA RIGHTS & PORTABILITY ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Data Rights (DPDP Act)',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.file_download_outlined, color: AppColors.royalBlue),
                        title: Text('Download My Data Export', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Get a JSON file containing your profile, addresses, orders & reviews', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        trailing: _isExporting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: _isExporting ? null : () => _handleDataExport(user.id),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                        title: Text('Request Data Correction', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('Report inaccurate information for rectification', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showCorrectionDialog(user.id, user.email ?? ''),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 4. GRIEVANCE REDRESSAL & POLICIES ───────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grievance Redressal & Policies',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data Protection Officer: Bhupendra Jogi\nEmail: privacy@marutistationery.com\nAddress: Maruti Stationery, Surat, Gujarat - 395007',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.push('/profile/about'),
                              child: Text('Privacy Policy', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.push('/profile/about'),
                              child: Text('Terms of Service', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.navyText)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── 5. DANGER ZONE: ACCOUNT DELETION ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Deletion & Data Erasure',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permanently delete your profile, saved addresses, and active carts. Order history is anonymized for financial compliance.',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.red.shade800),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: _isDeleting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.delete_forever_rounded, size: 18),
                          label: Text(
                            'Request Account Deletion',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          onPressed: _isDeleting ? null : () => _showDeleteAccountWorkflow(user.id),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyText)),
        ],
      ),
    );
  }
}

