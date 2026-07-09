import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_fcm_service.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetAudience = 'All Users';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);

    try {
      final db = FirebaseFirestore.instance;
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      if (_targetAudience == 'All Users') {
        // Send a global notification (userId: null)
        await db.collection('notifications').add({
          'title': title,
          'body': body,
          'type': 'offer',
          'userId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Dispatch Push Notification to all users topic
        await AdminFCMService.sendNotification(
          targetTokenOrTopic: '/topics/offers',
          title: title,
          body: body,
          data: {'type': 'offer'},
        );

      } else if (_targetAudience == 'Past Buyers') {
        // Find all unique users who have placed an order
        final ordersSnap = await db.collection('orders').get();
        final userIds = ordersSnap.docs.map((d) => d.data()['userId'] as String?).where((id) => id != null).toSet();

        // Write batch
        final batch = db.batch();
        int count = 0;
        
        for (final userId in userIds) {
          final docRef = db.collection('notifications').doc();
          batch.set(docRef, {
            'title': title,
            'body': body,
            'type': 'offer',
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
          count++;

          // Firestore batches support up to 500 writes
          if (count == 500) {
            await batch.commit();
            count = 0;
            // Get new batch
          }
        }
        
        if (count > 0) {
          await batch.commit();
        }

        // Fetch tokens for past buyers to send push notification
        for (final userId in userIds) {
          final userDoc = await db.collection('users').doc(userId).get();
          final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
          for (final token in tokens) {
            await AdminFCMService.sendNotification(
              targetTokenOrTopic: token,
              title: title,
              body: body,
              data: {'type': 'offer'},
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send broadcast: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Broadcast Notifications'),
        backgroundColor: context.colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send In-App Push Notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This message will appear in the user\'s notification tab inside the app.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _targetAudience,
                decoration: InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.group_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'All Users', child: Text('All Users')),
                  DropdownMenuItem(value: 'Past Buyers', child: Text('Past Buyers (At least 1 order)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _targetAudience = val);
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Notification Title (e.g. Flash Sale!)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Notification Message',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSending ? null : _sendBroadcast,
                child: _isSending
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
