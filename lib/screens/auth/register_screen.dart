import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart'
    as http; // Needed for automated background trigger
import '../../services/auth_service.dart';
import '../../services/notification_service.dart'; // Fetch device push addresses
import '../../config/app_config.dart'; // Clean pipeline endpoints
import '../../theme/cixio_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _error = 'Phone number is required for OTP authentication.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch the phone's hardware FCM push token
      String? deviceToken = await NotificationService.getDeviceToken();

      // 2. Commit the registration profile to the backend via service account
      await AuthService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: phone,
        deviceToken: deviceToken,
      );

      // 3. Command the engine to queue and fire the background OTP job
      // 3. Command the engine to queue and fire the background OTP job
      print("✅ About to trigger OTP for $phone");
      await _triggerOTP(phone);
      print("✅ OTP triggered, about to navigate");

      // 4. Smoothly route the user over to the 6-digit input verification view
      if (mounted) {
        print("✅ Widget still mounted, navigating to /verify-otp/$phone");
        context.go('/verify-otp/$phone');
        print("✅ Navigation call completed");
      } else {
        print("❌ Widget no longer mounted — navigation skipped");
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Tells FastAPI to queue a push task message into RabbitMQ
  Future<void> _triggerOTP(String phoneNumber) async {
    final String otpUrl =
        "${AppConfig.apiUrl}/auth/login/request-otp?phone=$phoneNumber";
    try {
      await http.post(Uri.parse(otpUrl));
    } catch (e) {
      print("Warning: Failed to auto-trigger notification dispatch script: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CixioColors.dark, Color(0xFF0D267A), CixioColors.navy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/cixio-logo-white.png',
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CixioColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Join CixioHub — TKM\'s AI platform',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                            validator: (v) => v != null && v.trim().length >= 2
                                ? null
                                : 'Enter your name',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => v != null && v.contains('@')
                                ? null
                                : 'Enter a valid email',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => v != null && v.trim().isNotEmpty
                                ? null
                                : 'Phone required for OTP verification',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outlined),
                            ),
                            validator: (v) => v != null && v.length >= 8
                                ? null
                                : 'Min 8 characters',
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Register & Verify Device'),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text(
                                'Already have an account? Sign in',
                                style: TextStyle(color: CixioColors.blue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
