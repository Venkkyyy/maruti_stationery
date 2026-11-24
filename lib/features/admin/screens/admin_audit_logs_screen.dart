import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/audit_log_model.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Security & Audit Logs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.navyText, fontSize: 17),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs by admin, action, or details...',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.royalBlue),
                filled: true,
                fillColor: AppColors.surfaceWarm,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('audit_logs').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                var logs = docs.map((d) => AuditLogModel.fromFirestore(d)).toList();

                if (_searchQuery.isNotEmpty) {
                  logs = logs.where((l) =>
                    l.action.toLowerCase().contains(_searchQuery) ||
                    l.adminName.toLowerCase().contains(_searchQuery) ||
                    l.description.toLowerCase().contains(_searchQuery) ||
                    l.targetType.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 54, color: AppColors.textHint.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        Text(
                          'No audit events logged yet.',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Admin actions (status updates, product changes, etc.) will appear here.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.action.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.royalBlue),
                                ),
                              ),
                              Text(
                                dateFormat.format(log.timestamp),
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log.description,
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Performed by: ${log.adminName}',
                            style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
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

