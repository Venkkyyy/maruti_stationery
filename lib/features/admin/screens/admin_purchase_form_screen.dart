import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/purchase_order_model.dart';
import '../../../models/supplier_model.dart';
import '../../../services/admin_audit_service.dart';

class AdminPurchaseFormScreen extends StatefulWidget {
  final PurchaseOrderModel? existingOrder;
  const AdminPurchaseFormScreen({super.key, this.existingOrder});

  @override
  State<AdminPurchaseFormScreen> createState() => _AdminPurchaseFormScreenState();
}

class _AdminPurchaseFormScreenState extends State<AdminPurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  late TextEditingController _invoiceCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _purchaseDate;
  PurchaseStatus _status = PurchaseStatus.received;
  bool _autoRestock = true;
  bool _isLoading = false;

  final List<_ItemEntry> _items = [];

  List<SupplierModel> _suppliers = [];

  @override
  void initState() {
    super.initState();
    final o = widget.existingOrder;
    _invoiceCtrl = TextEditingController(text: o?.invoiceNumber ?? '');
    _notesCtrl = TextEditingController(text: o?.notes ?? '');
    _purchaseDate = o?.purchaseDate ?? DateTime.now();
    _status = o?.status ?? PurchaseStatus.received;
    _autoRestock = o?.isRestocked ?? true;
    _selectedSupplierId = o?.supplierId;
    _selectedSupplierName = o?.supplierName ?? '';

    if (o != null) {
      for (final it in o.items) {
        _items.add(_ItemEntry(
          productId: it.productId,
          productName: it.productName,
          quantity: it.quantity,
          unitCostRupees: it.unitCost / 100,
        ));
      }
    } else {
      _items.add(_ItemEntry());
    }

    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('suppliers').orderBy('name').get();
      setState(() {
        _suppliers = snap.docs.map((d) => SupplierModel.fromFirestore(d)).toList();
        if (_selectedSupplierId == null && _suppliers.isNotEmpty) {
          _selectedSupplierId = _suppliers.first.id;
          _selectedSupplierName = _suppliers.first.name;
        }
      });
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    }
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, it) => sum + (it.quantity * it.unitCostRupees));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty || _items.any((it) => it.productName.trim().isEmpty || it.quantity <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid item with name and quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final purchaseId = widget.existingOrder?.id ?? const Uuid().v4();
      final orderNumber = widget.existingOrder?.orderNumber ?? 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final List<PurchaseItem> purchaseItems = _items.map((it) {
        final unitPaise = (it.unitCostRupees * 100).toInt();
        final totalPaise = (it.quantity * unitPaise);
        return PurchaseItem(
          productId: it.productId.isNotEmpty ? it.productId : const Uuid().v4(),
          productName: it.productName.trim(),
          quantity: it.quantity,
          unitCost: unitPaise,
          totalCost: totalPaise,
        );
      }).toList();

      final totalCostPaise = (_totalAmount * 100).toInt();

      final purchaseOrder = PurchaseOrderModel(
        id: purchaseId,
        orderNumber: orderNumber,
        supplierId: _selectedSupplierId ?? '',
        supplierName: _selectedSupplierName,
        invoiceNumber: _invoiceCtrl.text.trim(),
        purchaseDate: _purchaseDate,
        items: purchaseItems,
        totalCost: totalCostPaise,
        status: _status,
        notes: _notesCtrl.text.trim(),
        isRestocked: _autoRestock,
        createdAt: widget.existingOrder?.createdAt ?? DateTime.now(),
      );

      final batch = FirebaseFirestore.instance.batch();
      final poRef = FirebaseFirestore.instance.collection('purchases').doc(purchaseId);
      batch.set(poRef, purchaseOrder.toFirestore());

      // If auto-restock enabled and received, update product stock in Firestore if matching products exist
      if (_status == PurchaseStatus.received && _autoRestock && widget.existingOrder == null) {
        for (final it in purchaseItems) {
          if (it.productId.isNotEmpty) {
            final pRef = FirebaseFirestore.instance.collection('products').doc(it.productId);
            batch.set(pRef, {'stock': FieldValue.increment(it.quantity)}, SetOptions(merge: true));
            AdminAuditService.logStockMovement(
              productId: it.productId,
              productName: it.productName,
              quantityChange: it.quantity,
              previousStock: 0,
              newStock: it.quantity,
              reason: 'Purchase Inward (PO: $orderNumber)',
            );
          }
        }
      }

      await batch.commit();

      await AdminAuditService.logAction(
        action: widget.existingOrder == null ? 'Create Purchase Order' : 'Update Purchase Order',
        targetType: 'purchase',
        targetId: purchaseId,
        description: 'Purchase $orderNumber from $_selectedSupplierName for ${AppFormatters.formatPrice(totalCostPaise)}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase Order $orderNumber recorded!'), backgroundColor: AppColors.success),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingOrder == null ? 'New Purchase Order' : 'Edit Purchase',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            // Vendor selection card
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
                  Text('Supplier & Invoice Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyText)),
                  const SizedBox(height: 12),
                  if (_suppliers.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSupplierId,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyText),
                      decoration: InputDecoration(
                        labelText: 'Select Supplier*',
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSupplierId = val;
                          _selectedSupplierName = _suppliers.firstWhere((s) => s.id == val).name;
                        });
                      },
                    ),
                  ] else ...[
                    Text('No suppliers found. Please add suppliers first.', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _invoiceCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Vendor Invoice / Bill Number',
                      filled: true,
                      fillColor: AppColors.surfaceWarm,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Purchase Date',
                        filled: true,
                        fillColor: AppColors.surfaceWarm,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.royalBlue),
                      ),
                      child: Text(DateFormat('dd MMM yyyy').format(_purchaseDate), style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyText)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Line items header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Purchase Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navyText)),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_ItemEntry())),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Add Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.royalBlue)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Line items list
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.productName,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Item Name (e.g. Reynolds Gel Pen Box)*',
                              filled: true,
                              fillColor: AppColors.surfaceWarm,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) => item.productName = v,
                          ),
                        ),
                        if (_items.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.quantity > 0 ? item.quantity.toString() : '',
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Qty (Pcs/Box)*',
                              filled: true,
                              fillColor: AppColors.surfaceWarm,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) => setState(() => item.quantity = int.tryParse(v.trim()) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.unitCostRupees > 0 ? item.unitCostRupees.toString() : '',
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Cost/Unit (₹)*',
                              filled: true,
                              fillColor: AppColors.surfaceWarm,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (v) => setState(() => item.unitCostRupees = double.tryParse(v.trim()) ?? 0.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${(item.quantity * item.unitCostRupees).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.royalBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Inward Cost:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navyText)),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.royalBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Restock switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Auto-update inventory stock', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.navyText)),
              subtitle: Text('Directly increment stock quantities for these items', style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary)),
              value: _autoRestock,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _autoRestock = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Purchase Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ItemEntry {
  String productId;
  String productName;
  int quantity;
  double unitCostRupees;

  _ItemEntry({
    this.productId = '',
    this.productName = '',
    this.quantity = 0,
    this.unitCostRupees = 0.0,
  });
}

