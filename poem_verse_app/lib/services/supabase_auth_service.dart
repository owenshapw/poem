import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseAuthService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // 获取当前用户
  static User? get currentUser => _client.auth.currentUser;
  
  // 检查是否已登录
  static bool get isLoggedIn => currentUser != null;
  
  // 注册新用户
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );
      
      if (response.user != null) {
        return {
          'success': true,
          'user': response.user,
          'session': response.session,
          'message': '注册成功！请检查邮箱进行验证。',
        };
      } else {
        return {
          'success': false,
          'error': '注册失败',
        };
      }
    } on AuthException catch (e) {
      debugPrint('Supabase 注册错误: ${e.message}');
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      debugPrint('注册异常: $e');
      return {
        'success': false,
        'error': '注册过程中发生错误',
      };
    }
  }
  
  // 用户登录
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null && response.session != null) {
        return {
          'success': true,
          'user': response.user,
          'session': response.session,
          'token': response.session!.accessToken,
          'refresh_token': response.session!.refreshToken,
        };
      } else {
        return {
          'success': false,
          'error': '登录失败',
        };
      }
    } on AuthException catch (e) {
      debugPrint('Supabase 登录错误: ${e.message}');
      return {
        'success': false,
        'error': _getLocalizedErrorMessage(e.message),
      };
    } catch (e) {
      debugPrint('登录异常: $e');
      return {
        'success': false,
        'error': '登录过程中发生错误',
      };
    }
  }
  
  // 用户登出
  static Future<Map<String, dynamic>> signOut() async {
    try {
      await _client.auth.signOut();
      return {
        'success': true,
        'message': '登出成功',
      };
    } catch (e) {
      debugPrint('登出异常: $e');
      return {
        'success': false,
        'error': '登出失败',
      };
    }
  }
  
  // 重置密码
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: '${dotenv.env['SITE_URL']}/auth/reset-password',
      );
      return {
        'success': true,
        'message': '密码重置邮件已发送',
      };
    } on AuthException catch (e) {
      debugPrint('密码重置错误: ${e.message}');
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      debugPrint('密码重置异常: $e');
      return {
        'success': false,
        'error': '发送重置邮件失败',
      };
    }
  }
  
  // 更新密码
  static Future<Map<String, dynamic>> updatePassword({
    required String newPassword,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (response.user != null) {
        return {
          'success': true,
          'message': '密码更新成功',
        };
      } else {
        return {
          'success': false,
          'error': '密码更新失败',
        };
      }
    } on AuthException catch (e) {
      debugPrint('密码更新错误: ${e.message}');
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      debugPrint('密码更新异常: $e');
      return {
        'success': false,
        'error': '密码更新过程中发生错误',
      };
    }
  }
  
  // 获取当前用户信息
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final user = currentUser;
      if (user != null) {
        return {
          'success': true,
          'user': user,
        };
      } else {
        return {
          'success': false,
          'error': '用户未登录',
        };
      }
    } catch (e) {
      debugPrint('获取用户信息异常: $e');
      return {
        'success': false,
        'error': '获取用户信息失败',
      };
    }
  }
  
  // 刷新 session
  static Future<Map<String, dynamic>> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      if (response.session != null) {
        return {
          'success': true,
          'session': response.session,
          'token': response.session!.accessToken,
          'refresh_token': response.session!.refreshToken,
        };
      } else {
        return {
          'success': false,
          'error': 'Session 刷新失败',
        };
      }
    } on AuthException catch (e) {
      debugPrint('Session 刷新错误: ${e.message}');
      return {
        'success': false,
        'error': 'Session 已过期，请重新登录',
      };
    } catch (e) {
      debugPrint('Session 刷新异常: $e');
      return {
        'success': false,
        'error': 'Session 刷新失败',
      };
    }
  }
  
  // 监听认证状态变化
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  // 本地化错误消息
  static String _getLocalizedErrorMessage(String error) {
    switch (error.toLowerCase()) {
      case 'invalid login credentials':
        return '邮箱或密码错误';
      case 'email not confirmed':
        return '请先验证邮箱';
      case 'user not found':
        return '用户不存在';
      case 'invalid email':
        return '邮箱格式不正确';
      case 'password should be at least 6 characters':
        return '密码长度至少6位';
      case 'user already registered':
        return '该邮箱已被注册';
      default:
        return error;
    }
  }
}