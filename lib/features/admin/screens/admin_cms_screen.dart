import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/admin_audit_service.dart';

class AdminCmsScreen extends StatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  State<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends State<AdminCmsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aboutCtrl = TextEditingController();
  final _returnPolicyCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _announcementCtrl = TextEditingController();

  bool _isAnnouncementActive = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCmsContent();
  }

  Future<void> _loadCmsContent() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('content_cms').get();
      if (doc.exists) {
        final data = doc.data()!;
        _aboutCtrl.text = data['aboutUs'] ?? '';
        _returnPolicyCtrl.text = data['returnPolicy'] ?? '';
        _termsCtrl.text = data['terms'] ?? '';
        _announcementCtrl.text = data['announcement'] ?? '';
        _isAnnouncementActive = data['isAnnouncementActive'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading CMS: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _aboutCtrl.dispose();
    _returnPolicyCtrl.dispose();
    _termsCtrl.dispose();
    _announcementCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCms() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('settings').doc('content_cms').set({
        'aboutUs': _aboutCtrl.text.trim(),
        'returnPolicy': _returnPolicyCtrl.text.trim(),
        'terms': _termsCtrl.text.trim(),
        'announcement': _announcementCtrl.text.trim(),
        'isAnnouncementActive': _isAnnouncementActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AdminAuditService.logAction(
        action: 'Update Store CMS',
        targetType: 'settings',
        targetId: 'content_cms',
        description: 'Updated store policies, announcement bar, and About Us text.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store content updated successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Store Content & Policy CMS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Announcement bar section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Top Announcement Bar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText)),
                            Switch(
                              value: _isAnnouncementActive,
                              activeThumbColor: AppColors.primary,
                              onChanged: (v) => setState(() => _isAnnouncementActive = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _announcementCtrl,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. 🎉 Free Delivery on all stationery orders above ₹499 this week!',
                            filled: true,
                            fillColor: AppColors.surfaceWarm,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // About Us section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About Maruti Stationery', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _aboutCtrl,
                          maxLines: 4,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Your store history, values, and location description...',
                            filled: true,
                            fillColor: AppColors.surfaceWarm,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Return Policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Return & Refund Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _returnPolicyCtrl,
                          maxLines: 4,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Rules for returns, exchange period, and damaged goods claims...',
                            filled: true,
                            fillColor: AppColors.surfaceWarm,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms & Conditions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terms of Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _termsCtrl,
                          maxLines: 4,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Terms and customer agreements...',
                            filled: true,
                            fillColor: AppColors.surfaceWarm,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Save Store Content', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

