import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ad_model.dart';
import '../../../providers/ads_provider.dart';
import '../../../services/admin_product_service.dart';

class AdminAdFormScreen extends StatefulWidget {
  final AdModel? existingAd;
  const AdminAdFormScreen({super.key, this.existingAd});

  @override
  State<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends State<AdminAdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  File? _pickedVideoFile;
  File? _pickedImageFile;
  bool _isCompressing = false;
  String _compressProgress = '';
  final _adminProductService = AdminProductService();
  Subscription? _subscription;

  // Controllers
  late TextEditingController _videoUrlCtrl;
  late TextEditingController _thumbnailUrlCtrl;
  late TextEditingController _ctaLabelCtrl;
  late TextEditingController _ctaValueCtrl;
  late TextEditingController _freqCtrl;
  late TextEditingController _orderCtrl;

  AdCtaType _ctaType = AdCtaType.none;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEdit => widget.existingAd != null;

  @override
  void initState() {
    super.initState();
    final ad = widget.existingAd;
    _videoUrlCtrl = TextEditingController(text: ad?.videoUrl ?? '');
    _thumbnailUrlCtrl = TextEditingController(text: ad?.thumbnailUrl ?? '');
    _ctaLabelCtrl = TextEditingController(text: ad?.ctaLabel ?? 'Shop Now');
    _ctaValueCtrl = TextEditingController(text: ad?.ctaValue ?? '');
    _freqCtrl =
        TextEditingController(text: (ad?.placementFrequency ?? 8).toString());
    _orderCtrl =
        TextEditingController(text: (ad?.sortOrder ?? 0).toString());
    _ctaType = ad?.ctaType ?? AdCtaType.none;
    _isActive = ad?.isActive ?? true;
    _startDate = ad?.startDate;
    _endDate = ad?.endDate;

    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      if (mounted) {
        setState(() {
          _compressProgress = '${progress.toStringAsFixed(0)}%';
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _videoUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _ctaValueCtrl.dispose();
    _freqCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _isCompressing = true;
        _compressProgress = '0%';
      });

      // Compress video
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        pickedFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (mediaInfo != null && mediaInfo.file != null) {
        setState(() {
          _pickedVideoFile = mediaInfo.file;
          _videoUrlCtrl.text = 'Video selected and compressed (${(mediaInfo.filesize! / 1024 / 1024).toStringAsFixed(2)} MB)';
        });
        
        // Generate a thumbnail using VideoCompress
        final thumbnailFile = await VideoCompress.getFileThumbnail(pickedFile.path);
        if (thumbnailFile != null) {
          // Upload thumbnail if necessary, or let them pick one manually.
          // For now, let's keep it simple.
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error compressing video: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String finalVideoUrl = _videoUrlCtrl.text.trim();

    try {
      // 1. Upload video if a new one is selected
      if (_pickedVideoFile != null) {
        finalVideoUrl = await _adminProductService.uploadVideo(_pickedVideoFile!);
      }

      String finalThumbnailUrl = _thumbnailUrlCtrl.text.trim();
      if (_pickedImageFile != null) {
        final urls = await _adminProductService.uploadImages([_pickedImageFile!]);
        if (urls.isNotEmpty) {
          finalThumbnailUrl = urls.first;
        }
      }

      final ad = AdModel(
        id: widget.existingAd?.id ?? '',
        videoUrl: finalVideoUrl,
        thumbnailUrl: finalThumbnailUrl,
        ctaType: _ctaType,
        ctaValue: _ctaValueCtrl.text.trim(),
        ctaLabel: _ctaLabelCtrl.text.trim(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        placementFrequency: int.tryParse(_freqCtrl.text) ?? 8,
        sortOrder: int.tryParse(_orderCtrl.text) ?? 0,
        impressions: widget.existingAd?.impressions ?? 0,
        clicks: widget.existingAd?.clicks ?? 0,
        createdAt: widget.existingAd?.createdAt ?? DateTime.now(),
      );

      await saveAd(ad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Ad updated successfully!'
                : 'Ad created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving ad: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Ad' : 'New Video Ad'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Video ──────────────────────────────────────────
            _SectionHeader(label: 'Video Content'),
            const SizedBox(height: 12),

            // Video Upload Box
            GestureDetector(
              onTap: _isCompressing ? null : _pickAndCompressVideo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _videoUrlCtrl.text.isEmpty ? context.colors.error : context.colors.border,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    if (_isCompressing) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text('Compressing Video... $_compressProgress',
                          style: TextStyle(color: context.colors.textPrimary)),
                    ] else if (_pickedVideoFile != null) ...[
                      Icon(Icons.video_file_outlined, size: 48, color: context.colors.primary),
                      const SizedBox(height: 12),
                      Text('Video selected (Ready to upload)',
                          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                    ] else if (_videoUrlCtrl.text.isNotEmpty) ...[
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                      const SizedBox(height: 12),
                      Text('Video Uploaded',
                          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                    ] else ...[
                      Icon(Icons.video_library_outlined, size: 48, color: context.colors.textHint),
                      const SizedBox(height: 12),
                      Text('Tap to upload video from Gallery',
                          style: TextStyle(color: context.colors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('Required • Auto-compresses on device',
                          style: TextStyle(color: context.colors.textHint, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            if (_videoUrlCtrl.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text('Video is required', style: TextStyle(color: context.colors.error, fontSize: 12)),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: ≤ 30 seconds, 16:9 or 1:1 ratio. '
                      'The video will automatically be compressed before uploading.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thumbnail Upload Box
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (pickedFile != null) {
                  setState(() {
                    _pickedImageFile = File(pickedFile.path);
                    _thumbnailUrlCtrl.text = 'Local image selected';
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.border,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    if (_pickedImageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_pickedImageFile!, height: 100, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Text('Thumbnail selected',
                          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                    ] else if (_thumbnailUrlCtrl.text.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_thumbnailUrlCtrl.text, height: 100, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 12),
                      Text('Thumbnail Uploaded',
                          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                    ] else ...[
                      Icon(Icons.image_outlined, size: 48, color: context.colors.textHint),
                      const SizedBox(height: 12),
                      Text('Tap to upload a thumbnail (Optional)',
                          style: TextStyle(color: context.colors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),

            // ── Section: CTA ────────────────────────────────────────────
            _SectionHeader(label: 'Call-to-Action (optional)'),
            const SizedBox(height: 12),

            // CTA Type dropdown
            DropdownButtonFormField<AdCtaType>(
              value: _ctaType,
              decoration: _inputDecoration(
                  context, 'CTA Type', Icons.touch_app_outlined),
              items: const [
                DropdownMenuItem(
                    value: AdCtaType.none, child: Text('None (no button)')),
                DropdownMenuItem(
                    value: AdCtaType.product, child: Text('Link to Product')),
                DropdownMenuItem(
                    value: AdCtaType.category,
                    child: Text('Link to Category')),
                DropdownMenuItem(
                    value: AdCtaType.collection,
                    child: Text('Link to Collection / Tag')),
                DropdownMenuItem(
                    value: AdCtaType.url,
                    child: Text('External URL')),
              ],
              onChanged: (v) => setState(() => _ctaType = v ?? AdCtaType.none),
            ),
            const SizedBox(height: 16),

            if (_ctaType != AdCtaType.none) ...[
              if (_ctaType == AdCtaType.category)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _ctaValueCtrl.text.isNotEmpty ? _ctaValueCtrl.text : null,
                      hint: const Text('Choose a category'),
                      decoration: _inputDecoration(context, 'Link to Category', Icons.category_outlined),
                      items: docs.map((doc) {
                        return DropdownMenuItem(value: doc.id, child: Text(doc['name']));
                      }).toList(),
                      onChanged: (val) => setState(() {
                        if (val != null) _ctaValueCtrl.text = val;
                      }),
                      validator: (v) => v == null || v.isEmpty ? 'Select a category' : null,
                    );
                  },
                )
              else if (_ctaType == AdCtaType.product)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _ctaValueCtrl.text.isNotEmpty ? _ctaValueCtrl.text : null,
                      hint: const Text('Choose a product'),
                      decoration: _inputDecoration(context, 'Link to Product', Icons.inventory_2_outlined),
                      items: docs.map((doc) {
                        return DropdownMenuItem(value: doc.id, child: Text(doc['name']));
                      }).toList(),
                      onChanged: (val) => setState(() {
                        if (val != null) _ctaValueCtrl.text = val;
                      }),
                      validator: (v) => v == null || v.isEmpty ? 'Select a product' : null,
                    );
                  },
                )
              else
                _buildTextField(
                  controller: _ctaValueCtrl,
                  label: _ctaValueLabel(_ctaType),
                  hint: _ctaValueHint(_ctaType),
                  icon: Icons.link_rounded,
                  validator: (v) {
                    if (_ctaType != AdCtaType.none && (v == null || v.trim().isEmpty)) {
                      return 'Required for selected CTA type';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ctaLabelCtrl,
                label: 'Button Label',
                hint: 'e.g. Shop Now, Learn More, Explore',
                icon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 24),
            ],

            // ── Section: Scheduling ─────────────────────────────────────
            _SectionHeader(label: 'Campaign Scheduling (optional)'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Start Date',
                    value: _startDate != null ? fmt.format(_startDate!) : null,
                    onTap: () => _pickDate(isStart: true),
                    onClear: () => setState(() => _startDate = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'End Date',
                    value: _endDate != null ? fmt.format(_endDate!) : null,
                    onTap: () => _pickDate(isStart: false),
                    onClear: () => setState(() => _endDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Leave blank for always-on ads.',
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
            const SizedBox(height: 24),

            // ── Section: Placement ──────────────────────────────────────
            _SectionHeader(label: 'Feed Placement'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _freqCtrl,
                    label: 'Show after every N products',
                    hint: '8',
                    icon: Icons.repeat_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2) return 'Minimum 2';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _orderCtrl,
                    label: 'Display Priority (sort order)',
                    hint: '0',
                    icon: Icons.sort_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lower priority number = shown first when multiple ads are active. '
              '"Every N products" controls ad density in the scroll feed.',
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
            const SizedBox(height: 24),

            // ── Section: Status ─────────────────────────────────────────
            _SectionHeader(label: 'Status'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: SwitchListTile(
                title: Text('Active',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                subtitle: Text(
                  _isActive
                      ? 'Ad is visible in the customer feed'
                      : 'Ad is paused — not shown to customers',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeThumbColor: colors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Save button (bottom)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isEdit ? 'Save Changes' : 'Create Ad',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: _inputDecoration(context, label, icon).copyWith(
        hintText: hint,
      ),
    );
  }

  InputDecoration _inputDecoration(
      BuildContext context, String label, IconData icon) {
    final colors = context.colors;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: colors.textHint),
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colors.textSecondary),
    );
  }

  String _ctaValueLabel(AdCtaType type) {
    switch (type) {
      case AdCtaType.product:
        return 'Product ID';
      case AdCtaType.category:
        return 'Category ID';
      case AdCtaType.collection:
        return 'Collection Tag (e.g. back_to_school)';
      case AdCtaType.url:
        return 'External URL';
      default:
        return 'Value';
    }
  }

  String _ctaValueHint(AdCtaType type) {
    switch (type) {
      case AdCtaType.product:
        return 'Firestore product document ID';
      case AdCtaType.category:
        return 'Firestore category document ID';
      case AdCtaType.collection:
        return 'e.g. back_to_school';
      case AdCtaType.url:
        return 'https://example.com';
      default:
        return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.colors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: colors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      value != null ? colors.textPrimary : colors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child:
                    Icon(Icons.close_rounded, size: 16, color: colors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}
