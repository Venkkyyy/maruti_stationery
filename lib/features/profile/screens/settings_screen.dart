import 'package:maruti_stationery/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maruti_stationery/providers/theme_provider.dart';
import 'package:maruti_stationery/providers/auth_provider.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _promosEnabled = false;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _promosEnabled = prefs.getBool('promos_enabled') ?? false;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('NOTIFICATIONS'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Order updates and delivery status',
            icon: Icons.notifications_active_outlined,
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
              _saveSetting('notifications_enabled', val);
            },
          ),
          _buildSwitchTile(
            title: 'Promotional Offers',
            subtitle: 'New arrivals and exclusive discounts',
            icon: Icons.local_offer_outlined,
            value: _promosEnabled,
            onChanged: (val) {
              setState(() => _promosEnabled = val);
              _saveSetting('promos_enabled', val);
            },
          ),
          
          Divider(height: 32, thickness: 1, color: context.colors.border),
          
          _buildSectionHeader('APP SETTINGS'),
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Toggle dark theme',
            icon: Icons.dark_mode_outlined,
            value: isDarkMode,
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          _buildSwitchTile(
            title: 'Location Services',
            subtitle: 'Used for faster address suggestions',
            icon: Icons.location_on_outlined,
            value: _locationEnabled,
            onChanged: (val) {
              setState(() => _locationEnabled = val);
              _saveSetting('location_enabled', val);
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Icon(Icons.language_rounded, color: context.colors.textSecondary),
            title: Text(
              'Language',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),
            subtitle: Text(
              'English (UK)',
              style: TextStyle(fontSize: 13, color: context.colors.textHint),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
            onTap: () {},
          ),
          
          Divider(height: 32, thickness: 1, color: context.colors.border),
          
          _buildSectionHeader('ACCOUNT'),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
            title: Text(
              'Delete Account',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.error),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: context.colors.surface,
                  title: Text('Delete Account', style: TextStyle(color: context.colors.textPrimary)),
                  content: Text('Are you sure you want to delete your account? This action cannot be undone.', style: TextStyle(color: context.colors.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
                      onPressed: () async {
                        try {
                          await ref.read(authProvider.notifier).deleteAccount();
                          if (context.mounted) {
                            context.pop();
                            context.go('/onboarding');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.colors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      activeThumbColor: context.colors.primary,
      secondary: Icon(icon, color: context.colors.textSecondary),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: context.colors.textHint),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}






