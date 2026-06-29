// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../themes/app_colors.dart';
import '../home/home_screen.dart';
import 'otp_screen.dart';
import '../../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Text controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();

  final logger = Logger();

  final List<String> quotes = [
    "Notes, tasks, files, and ideas —\nall in one intelligent workspace.",
    "Ask questions. Find answers.\nGet work done.",
    "Work smarter.\nStay organized.",
  ];

  int currentQuote = 0;
  bool isLogin = true;
  bool _isGoogleSigningIn = false;

  @override
  void initState() {
    super.initState();
    rotateQuotes();
    _checkAndResetAuth();
  }

  Future<void> _checkAndResetAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null && mounted) {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await authProvider.logout();
      }
    }
  }

  void _showForgotPasswordFlow() {
    final emailController = TextEditingController(text: _emailController.text);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        final navigator = Navigator.of(dialogContext);
        
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your registered email address to receive a password reset token.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Email Address'),
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
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                // Pop the email dialog
                navigator.pop();

                // Show loading snackbar
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Requesting verification token...')),
                );

                final success = await authProvider.forgotPassword(email);

                if (!mounted) return;
                scaffoldMessenger.hideCurrentSnackBar();

                if (!success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Request failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Success - show reset form dialog
                _showResetPasswordConfirmDialog(email);
              },
              child: const Text('Send Token'),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordConfirmDialog(String email) {
    final tokenController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A verification token has been sent to $email. Enter it below along with your new password.',
                style: const TextStyle(fontSize: 13),
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
                final token = tokenController.text.trim();
                final newPass = newPasswordController.text;
                final confirmPass = confirmPasswordController.text;

                if (token.isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Please enter the token')),
                  );
                  return;
                }

                if (newPass != confirmPass) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                if (newPass.length < 6) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }

                // Show loading
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final resetSuccess = await authProvider.resetPassword(token, newPass);

                if (!mounted) return;
                // Pop loading
                navigator.pop();

                if (resetSuccess) {
                  // Pop confirm dialog
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password reset successfully! You can now log in.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Password reset failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void rotateQuotes() {
    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;
        setState(() {
          currentQuote = (currentQuote + 1) % quotes.length;
        });
        rotateQuotes();
      },
    );
  }

  /// GOOGLE SIGN-IN - Single correct method
  Future<void> _signInWithGoogle() async {
    logger.i('🟢 Google Sign-In started');
    
    if (_isGoogleSigningIn) return;
    
    setState(() => _isGoogleSigningIn = true);
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: AppConfig.googleClientId,
        scopes: ['email', 'profile'],
      );
      logger.i('🟢 GoogleSignIn instance created');
      
      await googleSignIn.signOut();
      logger.d('🟢 Signed out previous user');
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      logger.i('🟢 Google user selected: ${googleUser?.email}');
      
      if (googleUser == null) {
        logger.w('🔴 User cancelled sign in');
        setState(() => _isGoogleSigningIn = false);
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      logger.i('🟢 Got authentication tokens');
      
      // Use alias for Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      logger.i('🟢 Created Firebase credential');
      
      // Use alias for Firebase Auth
      final firebase_auth.UserCredential userCredential = 
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final firebase_auth.User? user = userCredential.user;
      logger.i('🟢 Firebase sign-in successful: ${user?.email}');
      
      if (user != null && mounted) {
        final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
        logger.i('🟢 Calling backend googleLogin...');
        
        final success = await authProvider.googleLogin(
          email: user.email ?? '',
          name: user.displayName ?? '',
          googleId: user.uid,
          photoUrl: user.photoURL,
        );
        
        logger.i('🟢 Backend googleLogin result: $success');
        
        if (success && mounted) {
          logger.i('🟢 Navigation to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (mounted) {
          logger.e('🔴 Backend login failed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in failed. Please try email login.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      logger.e('🔴 Google Sign-In Error: $e');
      logger.e('🔴 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in error: ${e.toString().split('\n')[0]}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
      logger.i('🟢 Google Sign-In completed');
    }
  }


  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 70),

                /// LOGO
                Text(
                  "SMART-HUB",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 14),

                /// QUOTES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      quotes[currentQuote],
                      key: ValueKey(currentQuote),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                /// AUTH SWITCHER
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: isLogin
                      ? buildLoginCard(textColor, secondaryText, cardColor)
                      : buildRegisterCard(textColor, secondaryText, cardColor),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// LOGIN CARD
  Widget buildLoginCard(Color? textColor, Color? secondaryText, Color? cardColor) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    return Container(
      key: const ValueKey("login"),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),

          /// EMAIL FIELD
          buildTextField(
            controller: _emailController,
            hint: "Email",
            icon: Icons.email_outlined,
            textColor: textColor,
          ),
          const SizedBox(height: 20),

          /// PASSWORD FIELD
          buildTextField(
            controller: _passwordController,
            hint: "Password",
            icon: Icons.lock_outline,
            obscure: true,
            textColor: textColor,
          ),
          const SizedBox(height: 14),

          /// FORGOT PASSWORD
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordFlow,
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: secondaryText),
              ),
            ),
          ),

          const SizedBox(height: 18),

          /// Error message
          if (authProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                authProvider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),

          /// LOGIN BUTTON
          authProvider.isLoading
              ? const CircularProgressIndicator()
              : buildButton(
                  text: "LOGIN",
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    final success = await authProvider.login(email, password);

                    if (success && mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    } else if (mounted && authProvider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.errorMessage!)),
                      );
                    }
                  },
                ),

          const SizedBox(height: 16),

          /// Divider
          Row(
            children: [
              Expanded(child: Divider(color: secondaryText?.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: secondaryText)),
              ),
              Expanded(child: Divider(color: secondaryText?.withValues(alpha: 0.3))),
            ],
          ),

          const SizedBox(height: 16),

          /// Google Sign In
          _isGoogleSigningIn
              ? const CircularProgressIndicator()
              : _buildGoogleSignInButton(),

          const SizedBox(height: 22),

          /// Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Not registered yet?",
                style: TextStyle(color: secondaryText),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = false;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                child: const Text(
                  "Register Now",
                  style: TextStyle(
                    color: AppColors.aiCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// REGISTER CARD
  Widget buildRegisterCard(Color? textColor, Color? secondaryText, Color? cardColor) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    return Container(
      key: const ValueKey("register"),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),

          /// FULL NAME FIELD
          buildTextField(
            controller: _nameController,
            hint: "Full Name",
            icon: Icons.person_outline,
            textColor: textColor,
          ),
          const SizedBox(height: 20),

          /// EMAIL FIELD
          buildTextField(
            controller: _registerEmailController,
            hint: "Email",
            icon: Icons.email_outlined,
            textColor: textColor,
          ),
          const SizedBox(height: 20),

          /// PASSWORD FIELD
          buildTextField(
            controller: _registerPasswordController,
            hint: "Password",
            icon: Icons.lock_outline,
            obscure: true,
            textColor: textColor,
          ),
          const SizedBox(height: 28),

          /// Error message
          if (authProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                authProvider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),

          /// REGISTER BUTTON
          authProvider.isLoading
              ? const CircularProgressIndicator()
              : buildButton(
                  text: "REGISTER",
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final email = _registerEmailController.text.trim();
                    final password = _registerPasswordController.text.trim();

                    if (name.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 6 characters')),
                      );
                      return;
                    }

                    final success = await authProvider.register(name, email, password);

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registration successful! Please verify the OTP sent to your email.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtpScreen(
                            email: email,
                            password: password,
                          ),
                        ),
                      );
                    } else if (mounted && authProvider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.errorMessage!)),
                      );
                    }
                  },
                ),

          const SizedBox(height: 16),

          /// Divider
          Row(
            children: [
              Expanded(child: Divider(color: secondaryText?.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("OR", style: TextStyle(color: secondaryText)),
              ),
              Expanded(child: Divider(color: secondaryText?.withValues(alpha: 0.3))),
            ],
          ),

          const SizedBox(height: 16),

          /// Google Sign In
          _isGoogleSigningIn
              ? const CircularProgressIndicator()
              : _buildGoogleSignInButton(),

          const SizedBox(height: 22),

          /// Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account?",
                style: TextStyle(color: secondaryText),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = true;
                    _nameController.clear();
                    _registerEmailController.clear();
                    _registerPasswordController.clear();
                  });
                },
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: AppColors.aiCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// GOOGLE SIGN-IN BUTTON
  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: const Text(
          "Continue with Google",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  /// PROFILE ICON
  Widget buildProfileIcon() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.aiCyan,
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.aiCyan,
        size: 38,
      ),
    );
  }

  /// TEXT FIELD
  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color? textColor,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: textColor?.withValues(alpha: 0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: textColor?.withValues(alpha: 0.5)),
      ),
    );
  }

  /// BUTTON
  Widget buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}