import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/cache_manager.dart';
import '../../services/settings_service.dart';
import '../../theme/cixio_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local cache?'),
        content: const Text(
          'This will remove cached chat messages, sessions, documents, '
          'todos, and profile data. Your account and login session '
          'will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await CacheManager.clearAll();
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local cache cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = settingsNotifier.themeMode == ThemeMode.dark ||
        (settingsNotifier.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settingsNotifier,
        builder: (context, _) => ListView(
          children: [
            // ── Appearance ───────────────────────────────────────
            const _SectionHeader(title: 'Appearance'),
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: CixioColors.blue,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                isDark ? 'Dark theme active' : 'Light theme active',
              ),
              value: isDark,
              onChanged: (value) {
                settingsNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            const Divider(),

            // ── Notifications ────────────────────────────────────
            const _SectionHeader(title: 'Notifications'),
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: CixioColors.blue,
              ),
              title: const Text('Push Notifications'),
              subtitle: Text(
                settingsNotifier.notificationsEnabled
                    ? 'Notifications enabled'
                    : 'Notifications disabled',
              ),
              value: settingsNotifier.notificationsEnabled,
              onChanged: (value) {
                settingsNotifier.setNotificationsEnabled(value);
              },
            ),
            const Divider(),

            // ── Data ─────────────────────────────────────────────
            const _SectionHeader(title: 'Data'),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: CixioColors.blue,
              ),
              title: const Text('Clear Local Cache'),
              subtitle: const Text(
                'Remove cached data. Login is preserved.',
              ),
              onTap: _clearCache,
            ),
            const Divider(),

            // ── About ────────────────────────────────────────────
            const _SectionHeader(title: 'About'),
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: CixioColors.blue,
              ),
              title: const Text('App Name'),
              subtitle: Text(_packageInfo?.appName ?? 'CixioHub'),
            ),
            ListTile(
              leading: const Icon(
                Icons.new_releases_outlined,
                color: CixioColors.blue,
              ),
              title: const Text('Version'),
              subtitle: Text(_packageInfo?.version ?? '-'),
            ),
            ListTile(
              leading: const Icon(
                Icons.build_outlined,
                color: CixioColors.blue,
              ),
              title: const Text('Build Number'),
              subtitle: Text(_packageInfo?.buildNumber ?? '-'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Made with ❤️ by CixioHub Team',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CixioColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: CixioColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
