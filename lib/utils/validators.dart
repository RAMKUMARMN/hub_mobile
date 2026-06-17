// lib/utils/validators.dart

class Validators {
  // ============ EMAIL VALIDATION ============
  
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // ============ PASSWORD VALIDATION ============
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  static String? validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }
    
    if (!hasSpecialChars) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // ============ NAME VALIDATION ============
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    
    return null;
  }
  
  // ============ TASK VALIDATION ============
  
  static String? validateTaskTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Task title is required';
    }
    
    if (value.length > 200) {
      return 'Task title cannot exceed 200 characters';
    }
    
    return null;
  }
  
  static String? validateTaskDescription(String? value) {
    if (value != null && value.length > 2000) {
      return 'Description cannot exceed 2000 characters';
    }
    return null;
  }
  
  // ============ NOTE VALIDATION ============
  
  static String? validateNoteTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Note title is required';
    }
    
    if (value.length > 200) {
      return 'Note title cannot exceed 200 characters';
    }
    
    return null;
  }
  
  // ============ WORKSPACE VALIDATION ============
  
  static String? validateWorkspaceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Workspace name is required';
    }
    
    if (value.length < 2) {
      return 'Workspace name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Workspace name cannot exceed 50 characters';
    }
    
    return null;
  }
  
  // ============ REMINDER VALIDATION ============
  
  static String? validateReminderTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Reminder title is required';
    }
    
    return null;
  }
  
  static String? validateReminderTime(DateTime? time) {
    if (time == null) {
      return 'Please select a reminder time';
    }
    
    if (time.isBefore(DateTime.now())) {
      return 'Reminder time cannot be in the past';
    }
    
    return null;
  }
  
  // ============ SEARCH VALIDATION ============
  
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty search is allowed (shows all)
    }
    
    if (value.length > 100) {
      return 'Search query is too long';
    }
    
    return null;
  }
  
  // ============ UTILITY METHODS ============
  
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
  
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$');
    return urlRegex.hasMatch(url);
  }
  
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }
}