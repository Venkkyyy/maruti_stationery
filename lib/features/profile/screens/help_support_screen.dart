import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colors.border),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: context.colors.textPrimary, size: 20),
          ),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContactCard(
            icon: Icons.chat_rounded,
            title: 'Live Chat',
            subtitle: 'Start a conversation now',
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.email_rounded,
            title: 'Email Support',
            subtitle: 'support@marutistationery.com',
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.phone_rounded,
            title: 'Call Us',
            subtitle: '+91 98765 43210',
          ),
          const SizedBox(height: 32),
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildFaqItem('How do I track my order?', 'You can track your order status in the "My Orders" section of your Profile.'),
          _buildFaqItem('What is your return policy?', 'We accept returns within 7 days of delivery for unused items in their original packaging.'),
          _buildFaqItem('Do you offer international shipping?', 'Currently, we only ship within India.'),
        ],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textHint,
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





