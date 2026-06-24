import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart' show User;
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_cache.dart';
import '../../utils/error_formatter.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _backendLoaded = false;
  bool _isOffline = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadCachedProfile();
    _loadProfile();
  }

  Future<void> _loadCachedProfile() async {
    final cached = await ProfileCache.loadProfile();
    if (!mounted || _backendLoaded || cached == null) return;
    setState(() {
      _user = cached;
      _nameCtrl.text = cached.fullName;
      _phoneCtrl.text = cached.phone ?? '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService().dio.get('/auth/me');
      if (!mounted) return;
      _backendLoaded = true;
      final user = User.fromJson(response.data as Map<String, dynamic>);
      setState(() {
        _user = user;
        _nameCtrl.text = user.fullName;
        _phoneCtrl.text = user.phone ?? '';
        _isLoading = false;
      });
      await ProfileCache.saveProfile(user);
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_user != null) _isOffline = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isSaving = true; });
    try {
      final response = await ApiService().dio.put('/auth/profile', data: {
        'full_name': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });
      setState(() {
        _user = User.fromJson(response.data as Map<String, dynamic>);
      });
      await ProfileCache.saveProfile(_user!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.format(e, fallback: 'Save failed.'))),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(isOffline: _isOffline),
          Expanded(
            child: _isLoading
                ? const SkeletonLoader(isProfile: true)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_user != null)
                    Center(
                      child: Text(
                        _user!.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
