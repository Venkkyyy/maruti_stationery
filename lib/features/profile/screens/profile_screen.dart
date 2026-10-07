import 'dart:ui';
import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.value;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.colors.textPrimary),
            onPressed: () => context.push('/profile/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFFFF1F2),
              Color(0xFFF0FDF4),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person, size: 32, color: context.colors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Small steps. Big dreams.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, size: 14, color: context.colors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.loyaltyPoints} Points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Orders Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/orders'),
                    child: Row(
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: context.colors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Orders Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _OrderAction(icon: Icons.receipt_long_outlined, label: 'My Orders', onTap: () => context.push('/orders')),
                  _OrderAction(icon: Icons.assignment_return_outlined, label: 'Returns', onTap: () => context.push('/orders')),
                  _OrderAction(icon: Icons.local_shipping_outlined, label: 'Track Order', onTap: () => context.push('/orders')),
                  _OrderAction(icon: Icons.headset_mic_outlined, label: 'Support', onTap: () => context.push('/profile/settings')),
                ],
              ),
              const SizedBox(height: 32),

              // Vertical List
              _ProfileListTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _ProfileListTile(
                icon: Icons.location_on_outlined,
                label: 'Address Book',
                onTap: () => context.push('/profile/address'),
              ),
              _ProfileListTile(
                icon: Icons.credit_card_outlined,
                label: 'Payment Methods',
                onTap: () => context.push('/profile/payment'),
              ),
              _ProfileListTile(
                icon: Icons.favorite_border_rounded,
                label: 'Wishlist',
                onTap: () => context.push('/wishlist'),
              ),
              _ProfileListTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
              _ProfileListTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => context.push('/profile/support'),
              ),
              _ProfileListTile(
                icon: Icons.info_outline_rounded,
                label: 'About Us',
                onTap: () => context.push('/profile/about'),
              ),
              const SizedBox(height: 24),
              
              // Logout Button
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/onboarding');
                  },
                  child: Text(
                    'Log Out',
                    style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  void _showUnimplementedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _OrderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OrderAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: context.colors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileListTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}






