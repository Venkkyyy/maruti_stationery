import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/notification_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.inkDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your Maruti Stationery account?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.value;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userId = firebaseUser?.uid ?? '';

    // Real stats
    final ordersAsync = ref.watch(watchUserOrdersProvider(userId));
    final wishlistAsync = ref.watch(watchWishlistProvider);
    final addressAsync = ref.watch(addressProvider);
    final notifsAsync = ref.watch(userNotificationsProvider);

    final ordersCount = ordersAsync.value?.length ?? 0;
    final wishlistCount = wishlistAsync.value?.length ?? 0;
    final addressCount = addressAsync.value?.length ?? 0;
    final notifsCount = notifsAsync.value?.length ?? 0;

    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (firebaseUser?.displayName?.isNotEmpty == true
            ? firebaseUser!.displayName!
            : 'Valued Customer');

    final displayEmail = user?.email?.isNotEmpty == true
        ? user!.email!
        : (firebaseUser?.email?.isNotEmpty == true
            ? firebaseUser!.email!
            : (user?.phone.isNotEmpty == true
                ? user!.phone
                : 'stationery@maruti.com'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: () => context.push('/profile/settings'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.inkDark,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ── 1. Profile Header Row ──────────────────────────────
            InkWell(
              onTap: () => context.push('/profile/edit'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar (Royal Blue circle with white silhouette matching mockup)
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.royalBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: firebaseUser?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  firebaseUser!.photoURL!,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 34,
                                color: Colors.white,
                              ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Edit icon
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 2. Account Statistics Cards ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    count: '$ordersCount',
                    label: 'Orders',
                    onTap: () => context.push('/orders'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    count: '$wishlistCount',
                    label: 'Wishlist',
                    onTap: () => context.push('/wishlist'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    count: '$addressCount',
                    label: 'Addresses',
                    onTap: () => context.push('/profile/address'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Admin Panel Shortcut (if Admin) ─────────────────────
            if (user?.isAdmin == true) ...[
              InkWell(
                onTap: () => context.push('/admin'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD8C6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── 3. Account Menu Container ───────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'My Orders',
                      onTap: () => context.push('/orders'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'My Addresses',
                      onTap: () => context.push('/profile/address'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      onTap: () => context.push('/wishlist'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      badgeCount: notifsCount > 0 ? notifsCount : null,
                      onTap: () => context.push('/notifications'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.credit_card_outlined,
                      label: 'Payment Methods',
                      onTap: () => context.push('/profile/payment'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () => context.push('/profile/support'),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push('/profile/settings'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 4. Logout Button (Pill button matching mockup) ──────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFFCD8C6),
                    width: 1.2,
                  ),
                  backgroundColor: const Color(0xFFFFF1EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Stat Card (Orders, Wishlist, Addresses) ────────────────────────
  Widget _buildStatCard({
    required BuildContext context,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu Item Row ──────────────────────────────────────────────────
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.royalBlue,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkDark,
                ),
              ),
            ),
            if (badgeCount != null) ...[
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.border,
      height: 1,
      thickness: 0.7,
      indent: 52,
    );
  }
}
