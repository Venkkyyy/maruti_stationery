import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/admin_fcm_service.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  bool _isSendingReminder = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _sendGlobalReminder() async {
    setState(() => _isSendingReminder = true);
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      for (final doc in usersSnap.docs) {
        final tokens = List<String>.from(doc.data()['fcmTokens'] ?? []);
        for (final token in tokens) {
          await AdminFCMService.sendNotification(
            targetTokenOrTopic: token,
            title: '🔥 Trending Now: Don\'t miss out!',
            body: 'Your cart misses you! Complete your purchase before items run out of stock.',
          );
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Global cart reminder sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reminder: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReminder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isSendingReminder
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.campaign_rounded),
            tooltip: 'Send Global Cart Reminder',
            onPressed: _isSendingReminder ? null : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Send Global Reminder'),
                  content: const Text('This will send a push notification to all customers reminding them about their carts. Proceed?'),
                  actions: [
                    TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary, foregroundColor: Colors.white),
                      onPressed: () {
                        context.pop();
                        _sendGlobalReminder();
                      },
                      child: const Text('Send'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                var docs = snapshot.data?.docs ?? [];
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final phone = (data['phone'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || phone.contains(_searchQuery);
                  }).toList();
                }
                
                if (docs.isEmpty) {
                  return Center(child: Text('No customers found', style: TextStyle(color: context.colors.textSecondary)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final user = UserModel.fromFirestore(docs[index]);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: context.colors.surface,
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.colors.primaryLight,
                          foregroundColor: context.colors.primary,
                          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C'),
                        ),
                        title: Text(user.name.isEmpty ? 'Unknown Customer' : user.name, style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        subtitle: Text(user.phone, style: TextStyle(color: context.colors.textSecondary)),
                        trailing: Icon(Icons.chevron_right, color: context.colors.border),
                        onTap: () {
                          context.push('/admin/users/${user.id}', extra: user);
                        },
                      ),
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
