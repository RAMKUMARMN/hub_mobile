// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api/api_services.dart';
import 'app_state.dart';
import 'workspace_provider.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  AppState? _appState;
  WorkspaceProvider? _workspaceProvider;  // ADD THIS

  // Getters
  String? get token => _token;
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
  
  void setWorkspaceProvider(WorkspaceProvider workspaceProvider) {  // ADD THIS
    _workspaceProvider = workspaceProvider;
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');

    if (token != null && userId != null) {
      _token = token;
      _userId = userId;
      _userName = userName;
      _userEmail = userEmail;
      _isAuthenticated = true;
      notifyListeners();
      
      // ✅ Load user data after session check with WorkspaceProvider
      if (_appState != null && _workspaceProvider != null && _userId != null) {
        _appState!.loadUserData(_userId!, _workspaceProvider!);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _token = response['token'] as String;
        _userId = response['user_id'] as String;
        _userName = response['name'] as String;
        _userEmail = response['email'] as String;
        _isAuthenticated = true;

        await _saveSession();

        // ✅ Load user data with WorkspaceProvider
        if (_appState != null && _workspaceProvider != null && _userId != null) {
          await _appState!.loadUserData(_userId!, _workspaceProvider!);
        }

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

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _token = response['token'] as String;
        _userId = response['user_id'] as String;
        _userName = response['name'] as String;
        _userEmail = response['email'] as String;
        _isAuthenticated = true;

        await _saveSession();

        // ✅ Load user data with WorkspaceProvider
        if (_appState != null && _workspaceProvider != null && _userId != null) {
          await _appState!.loadUserData(_userId!, _workspaceProvider!);
        }

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

  Future<bool> updateProfile({String? name, String? email}) async {
    _setLoading(true);

    try {
      if (_token == null) {
        _errorMessage = "Not authenticated";
        _setLoading(false);
        return false;
      }

      final response = await ApiService.updateProfile(
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

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    if (newPassword.length < 6) {
      _errorMessage = "Password must be at least 6 characters";
      _setLoading(false);
      return false;
    }

    try {
      final response = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response['error'] as String? ?? "Password change failed";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "Connection error";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.deleteAccount();

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

  Future<bool> googleLogin({
    required String email,
    required String name,
    required String googleId,
    required String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "name": name,
          "google_id": googleId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        _userId = data['user']['id'];
        _userName = data['user']['name'];
        _userEmail = data['user']['email'];
        _isAuthenticated = true;
        
        await _saveSession();
        
        // ✅ Load user data with WorkspaceProvider
        if (_appState != null && _workspaceProvider != null && _userId != null) {
          await _appState!.loadUserData(_userId!, _workspaceProvider!);
        }
        
        if (photoUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_url', photoUrl);
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['detail'] ?? "Google sign-in failed";
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
  
  Future<String?> getProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_url');
  }

  Future<void> _clearAllData() async {
    if (_appState != null && _userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data_${_userId!}');
      await _appState!.clearUserData(_userId!);
    }
    
    await logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workspace_items');
    await prefs.remove('recent_activities');
    await prefs.remove('all_workspace_items');
    await prefs.remove('workspaces');
    await prefs.remove('notifications_enabled');
    await prefs.remove('ai_suggestions_enabled');
    await prefs.remove('profile_image_path');
  }

  Future<void> logout() async {
    if (_appState != null && _userId != null) {
      await _appState!.clearUserData(_userId!);
    }
    
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isAuthenticated = false;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
    if (_userName != null) await prefs.setString('user_name', _userName!);
    if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}