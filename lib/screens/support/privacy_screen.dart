// lib/screens/support/privacy_screen.dart
import 'package:flutter/material.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Glass Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip, color: AppColors.aiCyan, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your privacy is our priority',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Privacy sections
              _buildSection(
                title: 'Data Collection',
                content: 'SmartHub collects minimal data necessary for app functionality. This includes:\n\n'
                         '• Task and note content you create\n'
                         '• Workspace organization preferences\n'
                         '• App usage patterns for productivity insights\n'
                         '• Device information for push notifications',
              ),
              
              _buildSection(
                title: 'Data Storage',
                content: 'Your data is primarily stored locally on your device. '
                         'Optional cloud sync (when available) will be encrypted. '
                         'You retain full ownership of your data.',
              ),
              
              _buildSection(
                title: 'AI Features',
                content: 'AI processing happens locally when possible. When external AI services are used, '
                         'data is anonymized and not stored permanently. No personal data is used to train AI models.',
              ),
              
              _buildSection(
                title: 'Third-Party Services',
                content: 'SmartHub may use:\n\n'
                         '• Firebase Cloud Messaging (notifications)\n'
                         '• Ollama (local AI inference)\n\n'
                         'These services have their own privacy policies.',
              ),
              
              _buildSection(
                title: 'Your Rights',
                content: 'You can:\n\n'
                         '• Export your data at any time\n'
                         '• Delete your account and all associated data\n'
                         '• Opt out of analytics and insights\n'
                         '• Disable AI features',
              ),
              
              // Footer
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated: May 26, 2026',
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For questions about privacy, contact: privacy@smarthub.com',
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}