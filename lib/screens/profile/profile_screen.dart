// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/theme_provider.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../services/local/notification_service.dart';
import '../../themes/app_colors.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_button.dart';
import '../../widgets/profile/edit_name_dialog.dart';
import '../auth/login_screen.dart';
import '../support/help_screen.dart';
import '../support/privacy_screen.dart';
import '../../services/navigation/navigation_service.dart';
// At the top of profile_screen.dart with other imports
import '../workspace_items/document_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  bool notifications = true;
  bool aiSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadProfileImage();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = prefs.getBool('notifications_enabled') ?? true;
      aiSuggestions = prefs.getBool('ai_suggestions_enabled') ?? true;
    });
  }

  // Add this method after _loadPreferences() or anywhere in the state class

Future<void> _clearCache() async {
  // Show loading indicator
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clearing cache...'), duration: Duration(seconds: 1)),
    );
  }
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.userId;
  
  // Clear user-specific document cache
  await DocumentCard.clearUserDocumentCache(userId: userId);
  
  if (mounted) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully! 🗑️'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

  Future<void> _loadProfileImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId ?? 'default';
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path_$userId');
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (image != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? 'default';
      
      setState(() {
        _profileImagePath = image.path;
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path_$userId', image.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  // NEW: Edit name only (not email)
  void _editName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentName = authProvider.userName ?? 'User';

    showDialog(
      context: context,
      builder: (context) => EditNameDialog(
        currentName: currentName,
        onNameUpdated: (newName) async {
          final success = await authProvider.updateProfile(name: newName);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name updated successfully!'), backgroundColor: Colors.green),
            );
            setState(() {});
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to update name'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _changePassword() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.userEmail;

    if (userEmail == null || userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found. Please log in again.')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show a loading indicator SnackBar
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Requesting verification token...')),
    );

    final success = await authProvider.forgotPassword(userEmail);

    if (!mounted) return;
    scaffoldMessenger.hideCurrentSnackBar();

    if (!success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send verification token.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Success - a token has been sent to their email. Now prompt for token and new password!
    final tokenController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogScaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A verification token has been sent to your email. Please check your inbox and enter it below along with your new password.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(hintText: 'Verification Token'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'New Password (min 6 characters)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tokenController.text.trim().isEmpty) {
                  dialogScaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Please enter the verification token')),
                  );
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  dialogScaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                
                if (newPasswordController.text.length < 6) {
                  dialogScaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }
                
                // Show loading on top of dialog
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final resetSuccess = await authProvider.resetPassword(
                  tokenController.text.trim(),
                  newPasswordController.text,
                );
                
                if (!mounted) return;
                // Pop loading indicator
                navigator.pop();

                if (resetSuccess) {
                  // Pop main dialog
                  navigator.pop();
                  dialogScaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  dialogScaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Failed to reset password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccount() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure? This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.deleteAccount();
              if (success && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to delete account'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final appState = Provider.of<AppState>(context, listen: false);
              appState.clearAllData();  
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getProductivityStats() {
    final appState = Provider.of<AppState>(context, listen: false);
    final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final workspaceId = workspaceProvider.currentWorkspace?.id;
    
    final items = workspaceId != null 
        ? appState.getItemsForWorkspace(workspaceId)
        : [];
    final activities = appState.recentActivities;

    return {
      'totalItems': items.length,
      'totalActivities': activities.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    final stats = _getProductivityStats();
    final userName = authProvider.userName ?? 'User';
    final userEmail = authProvider.userEmail ?? 'user@example.com';
    
    return PopScope(canPop: !Navigator.canPop(context),onPopInvokedWithResult: (didPop, result) {
      if (didPop) return; // If already popped by system, do nothing
      Navigator.pop(context); // Pop internally (back one screen)
    },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor),
            onPressed: () => NavigationService.goBack(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                // Profile Image with glass effect
                Stack(
                  children: [
                    GlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 80,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: _profileImagePath != null && File(_profileImagePath!).existsSync()
                                ? DecorationImage(image: FileImage(File(_profileImagePath!)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _profileImagePath == null
                              ? Icon(Icons.person_rounded, color: textColor, size: 60)
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GlassButton(
                        icon: Icons.camera_alt,
                        label: '',
                        onPressed: _pickProfileImage,
                        borderRadius: 20,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name with Edit Pencil
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _editName,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.aiCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.edit, size: 18, color: AppColors.aiCyan),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  userEmail,
                  style: TextStyle(color: secondaryText, fontSize: 14),
                ),

                const SizedBox(height: 24),

                // Stats Row - Glass cards
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Icon(Icons.folder_rounded, color: AppColors.aiCyan, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              stats['totalItems'].toString(),
                              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text('Items', style: TextStyle(color: secondaryText, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Icon(Icons.history, color: AppColors.aiCyan, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              stats['totalActivities'].toString(),
                              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text('Activities', style: TextStyle(color: secondaryText, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Settings tiles with glass effect
                _buildGlassTile(
                  icon: Icons.edit_rounded,
                  title: "Edit Name",
                  onTap: _editName,
                ),
                _buildGlassTile(
                  icon: Icons.lock_rounded,
                  title: "Change Password",
                  onTap: _changePassword,
                ),
                _buildGlassSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  title: "Dark Mode",
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                ),
                _buildGlassSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: "Notifications",
                  value: notifications,
                  onChanged: (value) async {
                    setState(() => notifications = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', value);
                    if (value) {
                      await NotificationService().initialize();
                    } else {
                      await NotificationService().cancelAllNotifications();
                    }
                  },
                ),
                _buildGlassSwitchTile(
                  icon: Icons.auto_awesome_rounded,
                  title: "AI Suggestions",
                  value: aiSuggestions,
                  onChanged: (value) async {
                    setState(() => aiSuggestions = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('ai_suggestions_enabled', value);
                  },
                ),
                _buildGlassTile(
                  icon: Icons.storage_rounded,
                  title: "Clear Cache",
                  onTap: _clearCache,
                ),
                _buildGlassTile(
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                _buildGlassTile(
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                _buildGlassTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Privacy Policy",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                ),
                const SizedBox(height: 16),
                _buildGlassTile(
                  icon: Icons.delete_forever_rounded,
                  title: "Delete Account",
                  onTap: _deleteAccount,
                  isDestructive: true,
                ),
                _buildGlassTile(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  onTap: _logout,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDestructive ? Colors.red : AppColors.aiCyan, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildGlassSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.aiCyan, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.aiCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}