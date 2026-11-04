import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null;



  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final error = await _authService.signIn(
        email: email,
        password: password,
      );

      if (error != null) {
        _errorMessage = error;
        return false;
      }

      _user = _authService.currentUser;

      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final error = await _authService.signInWithGoogle();

      if (error != null) {
        _errorMessage = error;
        return false;
      }

      _user = _authService.currentUser;
      return true;
    } catch (e) {
      _errorMessage = 'Google Login failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    if (_isLoading) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      final error = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      if (error != null) {
        _errorMessage = error;
        return false;
      }

      _user = _authService.currentUser;

      return true;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  Future<String?> resetPassword(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);

      return null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Password reset failed.';
      notifyListeners();

      return _errorMessage;
    } catch (e) {
      _errorMessage = 'Password reset failed.';
      notifyListeners();

      return _errorMessage;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();

    _user = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void _setLoading(bool value) {
    if (_isLoading == value) return;

    _isLoading = value;
    notifyListeners();
  }
}
