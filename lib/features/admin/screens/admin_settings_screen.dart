import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/algolia_admin_service.dart' as maruti_algolia;

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pointsPer100Controller = TextEditingController();
  final _pointsToRupeeRatioController = TextEditingController();
  
  final _deliveryFeeController = TextEditingController();
  final _freeThresholdController = TextEditingController();
  
  bool _isSaving = false;
  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isLoyaltyInitialized = false;
  bool _isDeliveryInitialized = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _pointsPer100Controller.dispose();
    _pointsToRupeeRatioController.dispose();
    _deliveryFeeController.dispose();
    _freeThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('support_details').set({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveLoyaltyRule() async {
    final pts = int.tryParse(_pointsPer100Controller.text.trim());
    final ratio = int.tryParse(_pointsToRupeeRatioController.text.trim());
    if (pts == null || pts < 0 || ratio == null || ratio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive numbers'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('loyalty_rule').set({
        'pointsPer100': pts,
        'pointsToRupeeRatio': ratio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loyalty rule saved!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDeliverySettings() async {
    final fee = int.tryParse(_deliveryFeeController.text.trim());
    final threshold = int.tryParse(_freeThresholdController.text.trim());
    
    if (fee == null || fee < 0 || threshold == null || threshold < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive numbers'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Store in paise (multiply by 100)
      await FirebaseFirestore.instance.collection('settings').doc('delivery_settings').set({
        'fee': fee * 100,
        'freeThreshold': threshold * 100,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery settings saved!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Support Details ──────────────────────────────────────────
          ref.watch(watchSupportDetailsProvider).when(
            data: (details) {
              if (!_isInitialized) {
                _emailController.text = details.email;
                _phoneController.text = details.phone;
                _isInitialized = true;
              }
              return _buildSupportSection(context);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          const SizedBox(height: 32),

          // ── Loyalty Points Rule ─────────────────────────────────────
          ref.watch(watchLoyaltyRuleProvider).when(
            data: (rule) {
              if (!_isLoyaltyInitialized) {
                _pointsPer100Controller.text = rule.pointsPer100.toString();
                _pointsToRupeeRatioController.text = rule.pointsToRupeeRatio.toString();
                _isLoyaltyInitialized = true;
              }
              return _buildLoyaltySection(context);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('Error loading loyalty rule: $e')),
          ),

          const SizedBox(height: 32),
          
          // ── Delivery Settings ─────────────────────────────────────
          ref.watch(watchDeliverySettingsProvider).when(
            data: (settings) {
              if (!_isDeliveryInitialized) {
                // Settings are in paise, so divide by 100 for the UI
                _deliveryFeeController.text = (settings.fee ~/ 100).toString();
                _freeThresholdController.text = (settings.freeThreshold ~/ 100).toString();
                _isDeliveryInitialized = true;
              }
              return _buildDeliverySection(context);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('Error loading delivery settings: $e')),
          ),

          const SizedBox(height: 32),

          // ── Quick Actions ───────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.sync_rounded, color: context.colors.primary),
            title: Text('Sync Products to Algolia Search', style: TextStyle(color: context.colors.textPrimary)),
            subtitle: Text('Push all products to Algolia index for fast search', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
            trailing: _isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _isSyncing ? null : () async {
              setState(() => _isSyncing = true);
              try {
                final count = await maruti_algolia.AlgoliaAdminService().bulkSyncAllProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Synced $count products to Algolia!', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Sync failed: $e', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSyncing = false);
              }
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.campaign_rounded, color: context.colors.primary),
            title: Text('Broadcast Notifications', style: TextStyle(color: context.colors.textPrimary)),
            onTap: () => context.push('/admin/settings/broadcast'),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: context.colors.error),
            title: Text('Logout', style: TextStyle(color: context.colors.error)),
            onTap: () {
              ref.read(authServiceProvider).signOut();
              context.go('/splash');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Support Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Support Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Support Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Loyalty Points Rule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure how many loyalty points customers earn per ₹100 spent.',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsPer100Controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Points earned per ₹100 spent',
              hintText: 'e.g. 10',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.stars_rounded, color: Color(0xFFB45309)),
              helperText: 'Set to 0 to disable loyalty points',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsToRupeeRatioController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Points required for ₹1 off',
              hintText: 'e.g. 10',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFB45309)),
              helperText: 'E.g. if 10, then 10 points = ₹1 off',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFFB45309),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveLoyaltyRule,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Loyalty Rule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: context.colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivery Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure delivery charges and the minimum order amount for free delivery.',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deliveryFeeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Delivery Fee (₹)',
              hintText: 'e.g. 40',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _freeThresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Free Delivery Threshold (₹)',
              hintText: 'e.g. 500',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              helperText: 'Orders above this amount will have free delivery',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveDeliverySettings,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Delivery Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // ── Maintenance ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: context.colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.build_circle_rounded, color: context.colors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Maintenance Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        setState(() => _isSaving = true);
                        final svc = maruti_algolia.AlgoliaAdminService();
                        final count = await svc.bulkSyncAllProducts();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully synced \$count products to Algolia!')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                    child: const Text('Bulk Sync Products to Algolia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Manually uploads all active products to your Algolia search engine.', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        setState(() => _isSaving = true);
                        final db = FirebaseFirestore.instance;
                        final returnsQuery = await db.collection('return_requests').where('status', isEqualTo: 'accepted').get();
                        int updated = 0;
                        for (var req in returnsQuery.docs) {
                          final orderId = req.data()['orderId'];
                          if (orderId != null) {
                            final orderDoc = await db.collection('orders').doc(orderId).get();
                            if (orderDoc.exists && orderDoc.data()?['status'] == 'cancelled') {
                              await db.collection('orders').doc(orderId).update({'status': 'returned'});
                              updated++;
                            }
                          }
                        }
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fixed \$updated old returned orders!')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                    child: const Text('Fix Old Returned Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Use this if previously accepted returns are showing up under Cancelled.', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 80), // padding for scroll
        ],
      ),
    );
  }
}
