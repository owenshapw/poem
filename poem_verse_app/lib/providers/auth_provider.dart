// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/services/supabase_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  String? get username => _user?['username'];
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  // 直接从用户对象获取用户ID (Supabase Auth)
  String? get userId => _user?['id'];

  // 检查邮箱是否已验证
  bool get isEmailConfirmed => _user?['email_confirmed'] ?? false;

  // 初始化时从本地存储加载认证状态
  Future<void> loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user');

      if (userJson != null) {
        _user = json.decode(userJson);
      }

      // 如果有token，验证其有效性
      if (_token != null) {
        final isValid = await _verifyToken();
        if (!isValid && _refreshToken != null) {
          // 尝试刷新token
          await _refreshAccessToken();
        }
      }

      notifyListeners();
    } catch (e) {
      // 加载认证状态失败，但应用仍可继续运行
      debugPrint('加载认证状态失败: $e');
    }
  }

  // 保存认证状态到本地存储
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_token != null) {
        await prefs.setString('access_token', _token!);
      } else {
        await prefs.remove('access_token');
      }

      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      } else {
        await prefs.remove('refresh_token');
      }

      if (_user != null) {
        await prefs.setString('user', json.encode(_user));
      } else {
        await prefs.remove('user');
      }
    } catch (e) {
      // 保存认证状态失败，但不影响应用继续运行
      debugPrint('保存认证状态失败: $e');
    }
  }

  // 验证token有效性
  Future<bool> _verifyToken() async {
    if (_token == null) return false;

    try {
      // 使用 Supabase 的当前用户检查来验证 token
      final response = await SupabaseAuthService.getCurrentUser();
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 刷新访问令牌
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await SupabaseAuthService.refreshSession();
      if (response['success'] == true) {
        _token = response['token'];
        _refreshToken = response['refresh_token'];
        await _saveAuthState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('刷新token失败: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );
      
      if (response['success'] == true) {
        _token = response['token'];
        _refreshToken = response['refresh_token'];
        
        // 从 Supabase User 对象提取用户信息
        final User user = response['user'];
        _user = {
          'id': user.id,
          'email': user.email,
          'username': user.userMetadata?['username'] ?? email.split('@')[0],
          'email_confirmed': user.emailConfirmedAt != null,
          'created_at': user.createdAt,
        };
        
        await _saveAuthState();
        return {'success': true, 'needs_migration': false};
      } else {
        return {
          'success': false,
          'needs_migration': false,
          'error': response['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'needs_migration': false,
        'error': e.toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseAuthService.signUp(
        email: email,
        password: password,
        username: username,
      );
      
      if (response['success'] == true) {
        final User user = response['user'];
        final Session? session = response['session'];
        
        // 从 Supabase User 对象提取用户信息
        _user = {
          'id': user.id,
          'email': user.email,
          'username': user.userMetadata?['username'] ?? username,
          'email_confirmed': user.emailConfirmedAt != null,
          'created_at': user.createdAt,
        };
        
        // 如果有 session（邮箱验证关闭时），保存 token
        if (session != null) {
          _token = session.accessToken;
          _refreshToken = session.refreshToken;
        }
        
        await _saveAuthState();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('注册失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseAuthService.resetPassword(email: email);
      return response['success'] == true;
    } catch (e) {
      debugPrint('重置密码失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseAuthService.updatePassword(
        newPassword: newPassword,
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('重置密码失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseAuthService.signOut();
    } catch (e) {
      // 登出失败不影响本地状态清除
      debugPrint('登出失败: $e');
    } finally {
      _token = null;
      _refreshToken = null;
      _user = null;
      await _saveAuthState();
      notifyListeners();
    }
  }

  // 获取当前用户信息
  Future<bool> getCurrentUser() async {
    try {
      final response = await SupabaseAuthService.getCurrentUser();
      if (response['success'] == true) {
        final User user = response['user'];
        _user = {
          'id': user.id,
          'email': user.email,
          'username': user.userMetadata?['username'] ?? user.email?.split('@')[0],
          'email_confirmed': user.emailConfirmedAt != null,
          'created_at': user.createdAt,
        };
        await _saveAuthState();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return false;
    }
  }

  // 确保token有效，如果无效则尝试刷新
  Future<String?> getValidToken() async {
    if (_token == null) return null;

    // 验证当前token
    final isValid = await _verifyToken();
    if (isValid) {
      return _token;
    }

    // 尝试刷新token
    final refreshed = await _refreshAccessToken();
    if (refreshed) {
      return _token;
    }

    // 刷新失败，清除认证状态
    await logout();
    return null;
  }
}
