import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/staff_model.dart';
import '../../../services/admin_audit_service.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  void _showStaffFormSheet({StaffModel? existingStaff}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StaffFormSheet(existingStaff: existingStaff),
    );
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove Staff Member', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText)),
        content: Text('Are you sure you want to remove "${staff.name}"?', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('staff').doc(staff.id).delete();
      await AdminAuditService.logAction(
        action: 'Remove Staff',
        targetType: 'staff',
        targetId: staff.id,
        description: 'Removed staff member "${staff.name}" (${staff.role.displayName})',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${staff.name} removed from staff'), backgroundColor: AppColors.error),
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
          'Staff & Role Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Staff Member',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 24),
            onPressed: () => _showStaffFormSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _showStaffFormSheet(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text('Add Team Member', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('staff').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final staffMembers = docs.map((d) => StaffModel.fromFirestore(d)).toList();

          if (staffMembers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'No staff members added yet.',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add managers, order clerks, and inventory clerks.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: staffMembers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final staff = staffMembers[index];
              return _StaffCard(
                staff: staff,
                onEdit: () => _showStaffFormSheet(existingStaff: staff),
                onDelete: () => _deleteStaff(staff),
              );
            },
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getRoleColor(StaffRole role) {
    switch (role) {
      case StaffRole.superAdmin:
        return AppColors.royalBlue;
      case StaffRole.storeManager:
        return AppColors.primary;
      case StaffRole.contentManager:
        return const Color(0xFF0D9488);
      case StaffRole.inventoryManager:
        return const Color(0xFF8B5CF6);
      case StaffRole.orderManager:
        return const Color(0xFF10B981);
      case StaffRole.supportStaff:
        return const Color(0xFFF59E0B);
      case StaffRole.viewer:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(staff.role);
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                      style: GoogleFonts.poppins(color: roleColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navyText),
                      ),
                      Text(
                        staff.email.isNotEmpty ? staff.email : staff.phone,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: staff.isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  await FirebaseFirestore.instance.collection('staff').doc(staff.id).update({'isActive': val});
                  await AdminAuditService.logAction(
                    action: 'Staff Status Toggle',
                    targetType: 'staff',
                    targetId: staff.id,
                    description: 'Set ${staff.name} to ${val ? 'Active' : 'Inactive'}',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              staff.role.displayName,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffFormSheet extends StatefulWidget {
  final StaffModel? existingStaff;
  const _StaffFormSheet({this.existingStaff});

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  StaffRole _selectedRole = StaffRole.orderManager;
  bool _isLoading = false;

  bool get _isEdit => widget.existingStaff != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStaff;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _selectedRole = s?.role ?? StaffRole.orderManager;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final staff = StaffModel(
        id: widget.existingStaff?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _selectedRole,
        isActive: widget.existingStaff?.isActive ?? true,
        createdAt: widget.existingStaff?.createdAt ?? DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('staff').doc(staff.id).set(staff.toFirestore());

      await AdminAuditService.logAction(
        action: _isEdit ? 'Update Staff Member' : 'Add Staff Member',
        targetType: 'staff',
        targetId: staff.id,
        description: '${_isEdit ? 'Updated' : 'Added'} staff "${staff.name}" as ${staff.role.displayName}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Staff updated!' : 'Staff member registered!'), backgroundColor: AppColors.success),
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
                    _isEdit ? 'Edit Staff Member' : 'Add Team Member',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyText),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Staff Full Name*',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Staff Email (Google account for login)*',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Mobile Phone Number*',
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Assigned Role & Privileges*', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.navyText)),
              const SizedBox(height: 8),
              DropdownButtonFormField<StaffRole>(
                value: _selectedRole,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: StaffRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
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
                      : Text(_isEdit ? 'Save Changes' : 'Grant Staff Access', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

