import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/ad_model.dart';
import '../../../providers/ads_provider.dart';

class AdminAdFormScreen extends StatefulWidget {
  final AdModel? existingAd;
  const AdminAdFormScreen({super.key, this.existingAd});

  @override
  State<AdminAdFormScreen> createState() => _AdminAdFormScreenState();
}

class _AdminAdFormScreenState extends State<AdminAdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

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
  }

  @override
  void dispose() {
    _videoUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _ctaLabelCtrl.dispose();
    _ctaValueCtrl.dispose();
    _freqCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ad = AdModel(
      id: widget.existingAd?.id ?? '',
      videoUrl: _videoUrlCtrl.text.trim(),
      thumbnailUrl: _thumbnailUrlCtrl.text.trim(),
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

    try {
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

            _buildTextField(
              controller: _videoUrlCtrl,
              label: 'Video URL *',
              hint: 'https://res.cloudinary.com/.../video.mp4',
              icon: Icons.smart_display_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Video URL is required';
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.isAbsolute ||
                    !uri.scheme.startsWith('http')) {
                  return 'Enter a valid https:// URL';
                }
                return null;
              },
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
                      'Recommended: ≤ 30 seconds, ≤ 30 MB, 16:9 or 1:1 ratio. '
                      'Large or long videos will slow the customer feed. '
                      'Upload to Cloudinary or Firebase Storage first, then paste the URL.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _thumbnailUrlCtrl,
              label: 'Thumbnail / Cover Image URL',
              hint: 'https://res.cloudinary.com/.../thumbnail.jpg',
              icon: Icons.image_outlined,
            ),
            const SizedBox(height: 8),

            Text(
              'Tip: Upload your video to Cloudinary or any CDN and paste the URL above. '
              'Recommended aspect ratio: 16:9 or 1:1 (max ~30 sec for best experience).',
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
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
              _buildTextField(
                controller: _ctaValueCtrl,
                label: _ctaValueLabel(_ctaType),
                hint: _ctaValueHint(_ctaType),
                icon: Icons.link_rounded,
                validator: (v) {
                  if (_ctaType != AdCtaType.none &&
                      (v == null || v.trim().isEmpty)) {
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
