// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api/auth_service.dart';
//import '../services/api/api_client.dart';
import 'app_state.dart';
import 'workspace_provider.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  AppState? _appState;
  WorkspaceProvider? _workspaceProvider;
  
  // Services
  final AuthService _authService = AuthService();
 //final ApiClient _apiClient = ApiClient();

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkExistingSession();
  }

  void setAppState(AppState appState) {
    _appState = appState;
  }
  
  void setWorkspaceProvider(WorkspaceProvider workspaceProvider) {
    _workspaceProvider = workspaceProvider;
  }

  // ============ SESSION MANAGEMENT ============

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final refreshToken = prefs.getString('auth_refresh_token');
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');

    if (token != null && userId != null) {
      _token = token;
      _refreshToken = refreshToken;
      _userId = userId;
      _userName = userName;
      _userEmail = userEmail;
      _isAuthenticated = true;
      notifyListeners();
      
      if (_appState != null && _workspaceProvider != null && _userId != null) {
        await _loadUserData();
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_appState == null || _workspaceProvider == null || _userId == null) return;
    
    _workspaceProvider!.setCurrentUserId(_userId!);
    await _workspaceProvider!.loadUserWorkspaces(_userId!);
    await _appState!.loadAllDataFromBackend();
    await _appState!.loadUserData(_userId!);
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_refreshToken != null) await prefs.setString('auth_refresh_token', _refreshToken!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
    if (_userName != null) await prefs.setString('user_name', _userName!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
  }

  // ============ LOGIN ============

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _token = response['token'] as String;
        _refreshToken = response['refresh_token'] as String?;
        _userId = response['user_id'] as String;
        _userName = response['name'] as String;
        _userEmail = response['email'] as String;
        _isAuthenticated = true;

        await _saveSession();
        await _loadUserData();

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Login failed";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error. Please try again.";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============ REGISTER ============

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Registration failed";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error. Please try again.";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============ OTP VERIFICATION ============

  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (response['success'] == true) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "OTP verification failed";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error. Please try again.";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============ RESEND OTP ============

  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resendOtp(
        email: email,
      );

      if (response['success'] == true) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Failed to resend OTP";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error. Please try again.";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============ GOOGLE LOGIN ============

  Future<bool> googleLogin({
    required String email,
    required String name,
    required String googleId,
    required String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ FIXED: Using _authService instead of direct http call
      final response = await _authService.googleLogin(
        email: email,
        name: name,
        googleId: googleId,
      );
      
      if (response['success'] == true) {
        _token = response['token'] as String;
        _refreshToken = response['refresh_token'] as String?;
        _userId = response['user_id'] as String;
        _userName = response['name'] as String;
        _userEmail = response['email'] as String;
        _isAuthenticated = true;
        
        await _saveSession();
        
        if (_appState != null && _userId != null) {
          await _appState!.loadUserData(_userId!);
        }
        
        if (photoUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_url', photoUrl);
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] ?? "Google sign-in failed";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Google sign-in failed: ${e.toString()}";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // ============ REFRESH TOKENS ============

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _authService.refreshToken(
        refreshToken: _refreshToken!,
      );

      if (response['success'] == true) {
        final data = response['data'];
        _token = data['access_token'] as String;
        _refreshToken = data['refresh_token'] as String;

        await _saveSession();
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============ PROFILE MANAGEMENT ============

  Future<bool> updateProfile({String? name, String? email}) async {
    _setLoading(true);

    try {
      if (_token == null) {
        _errorMessage = "Not authenticated";
        _setLoading(false);
        return false;
      }

      // ✅ FIXED: Using _authService instead of ApiService
      final response = await _authService.updateProfile(
        name: name,
        email: email,
      );

      if (response['success'] == true) {
        if (name != null) _userName = name;
        if (email != null) _userEmail = email;
        await _saveSession();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Update failed";
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Failed to update profile";
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email: email);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Forgot password request failed";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _clearError();

    if (newPassword.length < 6) {
      _errorMessage = "Password must be at least 6 characters";
      _setLoading(false);
      return false;
    }

    try {
      final response = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Password reset failed";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error";
      _setLoading(false);
      return false;
    }
  }

  Future<String?> getProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_url');
  }

  // ============ LOGOUT ============

  Future<void> logout() async {
    
    if (_appState != null && _userId != null) {
      await _appState!.clearUserData(_userId!);
    }
    
    // Clear WorkspaceProvider
    if (_workspaceProvider != null) {
      _workspaceProvider!.clearWorkspaces();
    }
    
    // Clear auth state
    _token = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isAuthenticated = false;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    notifyListeners();
  }

  // ============ DELETE ACCOUNT ============

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      // ✅ FIXED: Using _authService instead of ApiService
      final response = await _authService.deleteAccount();

      if (response['success'] == true) {
        await _clearAllData();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Account deletion failed";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error";
      _setLoading(false);
      return false;
    }
  }

  Future<void> _clearAllData() async {
    if (_appState != null && _userId != null) {
      await _appState!.deleteUserData(_userId!);
    }
    
    if (_workspaceProvider != null) {
      _workspaceProvider!.clearWorkspaces();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('profile_image_url');
    
    if (_userId != null) {
      await prefs.remove('workspace_items_$_userId');
      await prefs.remove('recent_activities_$_userId');
      await prefs.remove('focus_sessions_$_userId');
    }
    
    _token = null;
    _refreshToken = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isAuthenticated = false;
    _errorMessage = null;

    notifyListeners();
  }

  // ============ HELPER METHODS ============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}