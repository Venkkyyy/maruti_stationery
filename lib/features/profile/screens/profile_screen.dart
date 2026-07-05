import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // Blue header
          SliverAppBar(
            expandedHeight: 200,
            pinned: false,
            backgroundColor: context.colors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1557B0),
                      context.colors.primary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 38, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        userAsync.isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                user?.name ?? 'Guest User',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? '+91 -',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(value: '12', label: 'Orders'),
                        _StatDivider(),
                        _StatBox(value: '3', label: 'Wishlist'),
                        _StatDivider(),
                        _StatBox(value: '2', label: 'Addresses'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Admin Account section
                  if (user?.isAdmin == true) ...[
                    _SectionHeader('Admin Settings'),
                    const SizedBox(height: 8),
                    _ProfileSection([
                      _ProfileOption(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Dashboard',
                        subtitle: 'Manage products and orders',
                        onTap: () => context.go('/admin'),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // My Account section
                  _SectionHeader('My Account'),
                  const SizedBox(height: 8),
                  _ProfileSection([
                    _ProfileOption(
                      icon: Icons.receipt_long_rounded,
                      label: 'My Orders',
                      subtitle: '12 orders placed',
                      onTap: () => context.go('/orders'),
                    ),
                    _ProfileOption(
                      icon: Icons.location_on_outlined,
                      label: 'My Addresses',
                      subtitle: '2 saved addresses',
                      onTap: () => context.push('/profile/address'),
                    ),
                    _ProfileOption(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      subtitle: '3 items saved',
                      onTap: () => context.push('/wishlist'),
                    ),
                    _ProfileOption(
                      icon: Icons.credit_card_rounded,
                      label: 'Payment Methods',
                      subtitle: 'UPI, Cards',
                      onTap: () => context.push('/profile/payment'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Support section
                  _SectionHeader('Support'),
                  const SizedBox(height: 8),
                  _ProfileSection([
                    _ProfileOption(
                      icon: Icons.headset_mic_outlined,
                      label: 'Help & Support',
                      subtitle: 'FAQs, Chat, Call',
                      onTap: () => context.push('/profile/support'),
                    ),
                    _ProfileOption(
                      icon: Icons.star_border_rounded,
                      label: 'Rate the App',
                      subtitle: 'Share your feedback',
                      onTap: () => _showUnimplementedSnackBar(context, 'Redirecting to App Store...'),
                    ),
                    _ProfileOption(
                      icon: Icons.info_outline_rounded,
                      label: 'About Maruti Stationery',
                      subtitle: 'Version 1.0.0',
                      onTap: () => context.push('/profile/about'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Settings section
                  _SectionHeader('Preferences'),
                  const SizedBox(height: 8),
                  _ProfileSection([
                    _ProfileOption(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      subtitle: 'App preferences, language, theme',
                      onTap: () => context.push('/profile/settings'),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Logout
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/splash');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.errorLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              color: context.colors.error, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Maruti Stationery v1.0.0',
                      style: TextStyle(
                          fontSize: 11, color: context.colors.textHint),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36, color: context.colors.divider,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.colors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final List<_ProfileOption> options;
  const _ProfileSection(this.options);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: options.asMap().entries.map((e) {
          final isLast = e.key == options.length - 1;
          return Column(
            children: [
              _ProfileOptionTile(option: e.value),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileOption {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });
}

class _ProfileOptionTile extends StatelessWidget {
  final _ProfileOption option;
  const _ProfileOptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: option.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon, color: context.colors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}






