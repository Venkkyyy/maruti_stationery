import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/supplier_model.dart';
import '../../../services/admin_audit_service.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  String _searchQuery = '';

  void _showSupplierFormSheet({SupplierModel? existingSupplier}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SupplierFormSheet(existingSupplier: existingSupplier),
    );
  }

  Future<void> _deleteSupplier(SupplierModel supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Supplier', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText)),
        content: Text('Are you sure you want to delete "${supplier.name}"?', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('suppliers').doc(supplier.id).delete();
      await AdminAuditService.logAction(
        action: 'Delete Supplier',
        targetType: 'supplier',
        targetId: supplier.id,
        description: 'Deleted supplier "${supplier.name}"',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${supplier.name} removed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Supplier Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Supplier',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
            onPressed: () => _showSupplierFormSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showSupplierFormSheet(),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Supplier', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by vendor name, category, or contact...',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                filled: true,
                fillColor: AppColors.surfaceWarm,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Suppliers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('suppliers').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                var suppliers = docs.map((d) => SupplierModel.fromFirestore(d)).toList();

                if (_searchQuery.isNotEmpty) {
                  suppliers = suppliers.where((s) =>
                    s.name.toLowerCase().contains(_searchQuery) ||
                    s.contactPerson.toLowerCase().contains(_searchQuery) ||
                    s.category.toLowerCase().contains(_searchQuery) ||
                    s.phone.contains(_searchQuery)
                  ).toList();
                }

                if (suppliers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'No suppliers registered yet.',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to register your stationery vendors & wholesalers.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return _SupplierCard(
                      supplier: supplier,
                      onEdit: () => _showSupplierFormSheet(existingSupplier: supplier),
                      onDelete: () => _deleteSupplier(supplier),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final SupplierModel supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  supplier.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyText),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  supplier.category,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                ),
              ),
            ],
          ),
          if (supplier.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Contact: ${supplier.contactPerson}',
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                supplier.phone,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navyText),
              ),
              if (supplier.gstin.isNotEmpty) ...[
                const SizedBox(width: 16),
                const Icon(Icons.receipt_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'GSTIN: ${supplier.gstin}',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (supplier.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              supplier.address,
              style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (supplier.phone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_forwarded_rounded, color: AppColors.success, size: 20),
                  tooltip: 'Call Supplier',
                  onPressed: () => launchUrl(Uri.parse('tel:${supplier.phone}')),
                ),
              if (supplier.email.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.email_outlined, color: AppColors.royalBlue, size: 20),
                  tooltip: 'Email Supplier',
                  onPressed: () => launchUrl(Uri.parse('mailto:${supplier.email}')),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                tooltip: 'Edit Supplier',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierFormSheet extends StatefulWidget {
  final SupplierModel? existingSupplier;
  const _SupplierFormSheet({this.existingSupplier});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _categoryCtrl;
  bool _isLoading = false;

  bool get _isEdit => widget.existingSupplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingSupplier;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _contactCtrl = TextEditingController(text: s?.contactPerson ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _gstinCtrl = TextEditingController(text: s?.gstin ?? '');
    _categoryCtrl = TextEditingController(text: s?.category ?? 'Stationery');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supplier = SupplierModel(
        id: widget.existingSupplier?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : 'Stationery',
        createdAt: widget.existingSupplier?.createdAt ?? DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('suppliers').doc(supplier.id).set(supplier.toFirestore());

      await AdminAuditService.logAction(
        action: _isEdit ? 'Update Supplier' : 'Add Supplier',
        targetType: 'supplier',
        targetId: supplier.id,
        description: '${_isEdit ? 'Updated' : 'Added'} supplier "${supplier.name}"',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Supplier updated!' : 'Supplier added!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Supplier' : 'Add New Supplier',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Supplier / Business Name*', _nameCtrl, isRequired: true),
              const SizedBox(height: 12),
              _buildField('Contact Person Name', _contactCtrl),
              const SizedBox(height: 12),
              _buildField('Phone Number*', _phoneCtrl, isRequired: true, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('Email Address', _emailCtrl, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField('Category / Specialization (e.g. Pens, Paper, Art)', _categoryCtrl),
              const SizedBox(height: 12),
              _buildField('GSTIN', _gstinCtrl),
              const SizedBox(height: 12),
              _buildField('Office / Warehouse Address', _addressCtrl, maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Save Changes' : 'Register Supplier', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isRequired = false, TextInputType? keyboard, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceWarm,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}

