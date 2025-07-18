import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static String get baseUrl {
    // 优先使用环境变量，如果没有则使用配置类
    final url = dotenv.env['BACKEND_URL'];
    if (url != null) {
      return url;
    }
    return AppConfig.backendApiUrl;
  }

  static Future<Map<String, dynamic>> fetchHomeArticles() async {
    // 尝试主URL
    try {
      final url =
          '${AppConfig.backendApiUrl}/articles'; // Use the standard articles endpoint

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'PoemVerse/1.0 (iOS)',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 418) {
        throw Exception('418 error, trying backup URL');
      } else {
        throw Exception('Failed to load home articles: ${response.statusCode}');
      }
    } catch (e) {
      // 如果是418错误或其他网络错误，尝试备用URL
      try {
        final backupUrl =
            '${AppConfig.backupBackendBaseUrl}/api/articles'; // Use the standard articles endpoint

        final backupResponse = await http.get(
          Uri.parse(backupUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PoemVerse/1.0 (iOS)',
            'Connection': 'keep-alive',
          },
        );

        if (backupResponse.statusCode == 200) {
          return json.decode(backupResponse.body);
        } else {
          throw Exception('Both URLs failed: ${backupResponse.statusCode}');
        }
      } catch (backupError) {
        throw Exception('Failed to load home articles: $e -> $backupError');
      }
    }
  }

  static Future<List<Article>> fetchArticles({
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.backendApiUrl}/articles?page=$page&per_page=$perPage',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articlesJson = data['articles'] as List;
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load articles');
    }
  }

  static Future<Map<String, dynamic>> getMyArticles(
    String token,
    String userId,
  ) async {
    try {
      // 使用 Supabase 直接查询用户文章
      final client = Supabase.instance.client;
      
      // 查询用户的文章，包括通过迁移映射关联的文章
      final response = await client
          .from('user_articles_view')  // 使用我们创建的视图
          .select('*')
          .order('created_at', ascending: false);
      
      return {
        'articles': response,
        'total': response.length,
      };
    } catch (e) {
      debugPrint('从 Supabase 加载文章失败: $e');
      
      // 如果 Supabase 查询失败，回退到原来的 API 调用
      try {
        final response = await http.get(
          Uri.parse('${AppConfig.backendApiUrl}/articles/user/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to load my articles: ${response.statusCode}');
        }
      } catch (apiError) {
        throw Exception('Failed to load my articles from both Supabase and API: $e -> $apiError');
      }
    }
  }

  static final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // 检查是否需要迁移
      try {
        final migrationCheck = await checkMigrationStatus(data['token']);
        if (migrationCheck['needs_migration'] == true) {
          data['needs_migration'] = true;
          data['migration_message'] = migrationCheck['message'];
        }
      } catch (e) {
        // 迁移状态检查失败，但不影响登录流程
        debugPrint('迁移状态检查失败: $e');
        // 默认不需要迁移
        data['needs_migration'] = false;
      }

      return data;
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '登录失败');
    }
  }

  static Future<Map<String, dynamic>> checkMigrationStatus(String token) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/migration-status');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'needs_migration': false};
    }
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String username,
  ) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '注册失败');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? '发送邮件失败');
    }
  }

  static Future<void> resetPassword(
    String accessToken,
    String newPassword,
  ) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'access_token': accessToken,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? '重置密码失败');
    }
  }

  // 新增的认证相关方法
  static Future<Map<String, dynamic>> logout(String token) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/logout');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '登出失败');
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/refresh');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Token刷新失败');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '获取用户信息失败');
    }
  }

  static Future<Map<String, dynamic>> verifyToken(String token) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/verify-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'access_token': token}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'valid': false, 'error': 'Token验证失败'};
    }
  }

  static Future<Map<String, dynamic>> migrateUser(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    // 使用 Supabase Auth 进行用户迁移
    try {
      debugPrint('使用 Supabase 迁移用户: $email');

      // 1. 首先尝试使用新密码直接登录（如果用户已经在 Supabase 中存在）
      try {
        final loginResult = await SupabaseAuthService.signIn(
          email: email,
          password: newPassword,
        );
        
        if (loginResult['success'] == true) {
          // 登录成功后，创建用户映射
          await _createUserMigrationMapping(email);
          
          return {
            'success': true,
            'message': '账户已升级，使用新密码登录成功。',
            'user': loginResult['user'],
          };
        }
      } catch (e) {
        debugPrint('新密码登录失败，尝试注册: $e');
      }

      // 2. 如果登录失败，尝试注册新用户
      String username = email.split('@')[0];
      final registerResult = await SupabaseAuthService.signUp(
        email: email,
        password: newPassword,
        username: username,
      );

      if (registerResult['success'] == true) {
        // 注册成功后，创建用户映射
        await _createUserMigrationMapping(email);
        
        return {
          'success': true,
          'message': '账户升级成功！请使用新密码登录。',
          'user': registerResult['user'],
        };
      } else {
        throw Exception('注册失败: ${registerResult['error']}');
      }
    } catch (e) {
      debugPrint('迁移异常: $e');
      return {
        'success': false,
        'error': '账户升级失败: $e',
      };
    }
  }

  // 创建用户迁移映射的辅助方法
  static Future<void> _createUserMigrationMapping(String email) async {
    try {
      debugPrint('为用户创建迁移映射: $email');
      
      // 首先检查旧用户是否存在
      final client = Supabase.instance.client;
      
      // 查找旧用户ID
      final oldUserQuery = await client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      if (oldUserQuery != null) {
        debugPrint('找到旧用户ID: ${oldUserQuery['id']}');
        
        // 调用 Supabase 函数创建映射
        await client.rpc('create_user_migration_mapping', params: {
          'p_email': email,
          'p_old_user_id': oldUserQuery['id'].toString(),
        });
        
        debugPrint('用户迁移映射创建成功');
      } else {
        debugPrint('警告：在 users 表中未找到邮箱 $email 的记录');
        
        // 仍然尝试调用函数，让函数自己查找
        await client.rpc('create_user_migration_mapping', params: {
          'p_email': email,
        });
      }
    } catch (e) {
      debugPrint('创建用户迁移映射失败: $e');
      // 不抛出错误，因为这不应该阻止迁移过程
    }
  }

  static Future<http.Response> getArticles(String token) async {
    return await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<Article?> createArticle(
    String token,
    String title,
    String content,
    List<String> tags,
    String author, {
    String? previewImageUrl,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'content': content,
      'tags': tags,
      'author': author,
    };

    if (previewImageUrl != null) {
      body['preview_image_url'] = previewImageUrl;
    }

    final response = await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Article.fromJson(data['article']);
    } else {
      return null;
    }
  }

  static Future<http.Response> generateImage(
    String token,
    String articleId,
  ) async {
    return await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/generate'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{'article_id': articleId}),
    );
  }

  static Future<http.Response> generatePreview(
    String token,
    String title,
    String content,
    List<String> tags,
    String author,
  ) async {
    return await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/generate/preview'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'content': content,
        'tags': tags,
        'author': author,
      }),
    );
  }

  static Future<http.Response> deleteArticle(
    String token,
    String articleId,
  ) async {
    return await http.delete(
      Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> put(
    Uri url, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  static String getImageUrlWithVariant(String? imageUrl, String variant) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    String fullUrl = buildImageUrl(imageUrl);
    return fullUrl.replaceAll('headphoto', variant);
  }

  static String buildImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    final fullUrl = '${AppConfig.backendBaseUrl}$imageUrl';
    return fullUrl;
  }

  static Future<Article> getArticleDetail(String articleId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 兼容返回结构 {"article": {...}}
      final articleJson = data['article'] ?? data;
      return Article.fromJson(articleJson);
    } else {
      throw Exception('获取详情失败: ${response.statusCode}');
    }
  }
}
