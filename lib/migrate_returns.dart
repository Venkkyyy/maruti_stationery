import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;
  
  print('Fetching return requests...');
  final returnsQuery = await db.collection('return_requests').where('status', isEqualTo: 'accepted').get();
  
  int updated = 0;
  for (var req in returnsQuery.docs) {
    final orderId = req.data()['orderId'];
    if (orderId != null) {
      final orderDoc = await db.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        if (orderDoc.data()?['status'] == 'cancelled') {
          print('Updating order \$orderId from cancelled to returned');
          await db.collection('orders').doc(orderId).update({'status': 'returned'});
          updated++;
        }
      }
    }
  }
  
  print('Migration complete. Updated \$updated orders.');
}
