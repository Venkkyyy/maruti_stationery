import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Admin Settings'),
        backgroundColor: context.colors.surface,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.storefront_outlined, color: context.colors.primary),
            title: Text('Return to Customer View', style: TextStyle(color: context.colors.textPrimary)),
            onTap: () => context.go('/home'),
          ),
          const Divider(),
          ListTile(
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
}
