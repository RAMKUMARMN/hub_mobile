// lib/screens/support/help_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/glass/glass_card.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFaqCard(
                question: 'How do I create a task?',
                answer: 'Tap the "Tasks" quick action on home screen, or go to Workspace and tap the + button.',
              ),
              _buildFaqCard(
                question: 'How does the AI assistant work?',
                answer: 'Our AI can summarize tasks, provide productivity insights, set reminders, and answer questions about your workspace.',
              ),
              _buildFaqCard(
                question: 'Is my data private?',
                answer: 'Yes. SmartHub prioritizes privacy. Your data is stored locally initially, with optional cloud sync coming soon.',
              ),
              _buildFaqCard(
                question: 'Can I use SmartHub offline?',
                answer: 'Most features work offline including notes, tasks, and local reminders. AI features require internet connection.',
              ),
              _buildFaqCard(
                question: 'How do I delete my account?',
                answer: 'Go to Profile → Delete Account. This will remove all your data from the app.',
              ),
              
              const SizedBox(height: 32),
              
              // Contact Section
              Text(
                'Contact Us',
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@smarthub.com',
                onTap: () => _launchEmail(),
              ),
              _buildContactCard(
                icon: Icons.chat_outlined,
                title: 'Live Chat',
                subtitle: 'Mon-Fri, 9AM-6PM',
                onTap: () => _showComingSoon(context),
              ),
              _buildContactCard(
                icon: Icons.article_outlined,
                title: 'Documentation',
                subtitle: 'User guides and tutorials',
                onTap: () => _showComingSoon(context),
              ),
              
              const SizedBox(height: 32),
              
              // Version Info
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqCard({
    required String question,
    required String answer,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.aiCyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.aiCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.aiCyan, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'support@smarthub.com');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!'), duration: Duration(seconds: 1)),
    );
  }
}