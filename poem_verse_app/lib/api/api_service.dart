import 'dart:convert';
import 'dart:async'; // 添加这个导入以使用TimeoutException
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 添加这个导入以使用MediaType
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
    
    debugPrint('创建文章请求: ${jsonEncode(body)}');
    debugPrint('API URL: ${AppConfig.backendApiUrl}/articles');

    try {
      // 尝试获取后端API的有效令牌
      String apiToken = token;
      
      try {
        // 尝试使用Supabase用户的邮箱和一个通用密码登录后端API
        // 这是一个临时解决方案，用于测试
        final client = Supabase.instance.client;
        final currentUser = client.auth.currentUser;
        
        if (currentUser != null && currentUser.email != null) {
          debugPrint('尝试使用后端API登录: ${currentUser.email}');
          
          // 尝试使用通用密码登录
          final loginResponse = await http.post(
            Uri.parse('${AppConfig.backendApiUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': currentUser.email,
              'password': 'test123', // 尝试使用通用密码
            }),
          );
          
          if (loginResponse.statusCode == 200) {
            final loginData = json.decode(loginResponse.body);
            if (loginData['token'] != null) {
              apiToken = loginData['token'];
              debugPrint('成功获取后端API令牌');
            }
          } else {
            debugPrint('后端API登录失败: ${loginResponse.statusCode}');
          }
        }
      } catch (loginError) {
        debugPrint('尝试获取后端API令牌失败: $loginError');
      }
      
      // 使用获取到的令牌发送请求
      final response = await http.post(
        Uri.parse('${AppConfig.backendApiUrl}/articles'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode(body),
      );
      
      debugPrint('创建文章响应状态码: ${response.statusCode}');
      debugPrint('创建文章响应内容: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Article.fromJson(data['article']);
      } else {
        // 尝试解析错误信息
        String errorMessage = '创建文章失败: 状态码 ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // 解析错误信息失败，使用默认错误信息
        }
        debugPrint('创建文章错误: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('创建文章异常: $e');
      rethrow; // 重新抛出异常，让调用者处理
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

  // 格式化图片URL，将Cloudflare URL转换为shipian.app域名
  static String _formatImageUrl(String url) {
    if (url.isEmpty) return url;
    
    // 使用正则表达式提取图片ID
    final regex = RegExp(r'imagedelivery\.net/[^/]+/([\w-]+)/public');
    final match = regex.firstMatch(url);
    
    if (match != null && match.groupCount >= 1) {
      final imageId = match.group(1);
      return 'https://images.shipian.app/images/$imageId/headphoto';
    }
    
    return url;
  }
  
  // 生成诗篇的提示词
  static Map<String, String> _generatePromptFromPoem(String title, String content, List<String> tags) {
    final stylePrompts = [
      "lyrical abstract painting",
      "Helen Frankenthaler",
      "Sam Francis",
      "Cy Twombly",
      "Joan Mitchell",
      "Franz Kline",
      "Lee Krasner",
      "dynamic gestural lines",
      "floating speckles of color",
      "dry-brush strokes on coarse canvas",
      "light color fields with painterly texture",
      "playful composition with vibrant rhythm"
    ];
    
    final colorPalette = "sky blue, blush pink, ochre yellow, lavender grey, pale jade, ivory white";
    
    final basePrompt = "${stylePrompts.join(', ')}, $colorPalette, high quality, sharp, balanced composition";
    final negativePrompt = "text, words, letters, low quality, blurry, distorted, ugly, deformed";
    
    return {
      'prompt': basePrompt,
      'negative_prompt': negativePrompt
    };
  }

  static Future<http.Response> generatePreview(
    String token,
    String title,
    String content,
    List<String> tags,
    String author,
  ) async {
    final requestBody = <String, dynamic>{
      'title': title,
      'content': content,
      'tags': tags,
      'author': author,
    };
    
    debugPrint('生成预览请求: ${jsonEncode(requestBody)}');
    
    try {
      // 首先尝试使用后端API生成预览图片
      debugPrint('尝试使用后端API生成预览图片');
      final url = Uri.parse('${AppConfig.backendApiUrl}/generate/preview');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 180), // 设置更长的超时时间，因为后端生成图片可能需要时间
        onTimeout: () {
          throw TimeoutException('后端API请求超时');
        },
      );
      
      debugPrint('后端预览生成响应状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('后端预览生成成功: ${responseData['preview_url']}');
        return response;
      } else {
        debugPrint('后端预览生成失败: ${response.body}');
        throw Exception('后端预览生成失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('后端预览生成异常，尝试使用前端生成: $e');
      
      // 如果后端生成失败，尝试使用前端HuggingFace API生成
      try {
        // 1. 生成提示词
        final prompts = _generatePromptFromPoem(title, content, tags);
        final prompt = prompts['prompt']!;
        final negativePrompt = prompts['negative_prompt']!;
        
        debugPrint('生成的提示词: $prompt');
        debugPrint('生成的负面提示词: $negativePrompt');
        
        // 2. 使用HuggingFace API生成图片
        Uint8List? imageBytes;
        
        final hfApiKey = dotenv.env['HF_API_KEY'];
        if (hfApiKey != null) {
          debugPrint('使用HuggingFace API生成图片');
          
          try {
            // 创建一个客户端，设置更长的超时时间
            final client = http.Client();
            final request = http.Request(
              'POST',
              Uri.parse('https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-5'),
            );
            
            // 设置请求头和请求体
            request.headers['Authorization'] = 'Bearer $hfApiKey';
            request.headers['Content-Type'] = 'application/json';
            
            // 使用最简单的请求格式
            request.body = jsonEncode({
              'inputs': prompt
            });
            
            debugPrint('发送到HuggingFace的请求: ${request.body}');
            
            // 发送请求，设置超时时间为120秒
            final streamedResponse = await client.send(request).timeout(
              const Duration(seconds: 120),
              onTimeout: () {
                debugPrint('HuggingFace API请求超时');
                client.close();
                throw TimeoutException('HuggingFace API请求超时');
              },
            );
            
            final hfResponse = await http.Response.fromStream(streamedResponse);
            
            if (hfResponse.statusCode == 200) {
              imageBytes = hfResponse.bodyBytes;
              debugPrint('成功从HuggingFace获取图片数据: ${imageBytes.length} 字节');
            } else {
              debugPrint('HuggingFace API请求失败: ${hfResponse.statusCode}');
              debugPrint('HuggingFace API响应内容: ${hfResponse.body}');
              throw Exception('HuggingFace API请求失败: ${hfResponse.statusCode}');
            }
          } catch (e) {
            debugPrint('HuggingFace API异常: $e');
            throw Exception('HuggingFace API异常: $e');
          }
        } else {
          throw Exception('HF_API_KEY未设置');
        }
        
        // 4. 将图片上传到Cloudflare Images
        final cfAccountId = dotenv.env['CLOUDFLARE_ACCOUNT_ID'];
        final cfApiToken = dotenv.env['CLOUDFLARE_API_TOKEN'];
        
        if (cfAccountId == null || cfApiToken == null) {
          throw Exception('Cloudflare配置未设置');
        }
        
        debugPrint('上传图片到Cloudflare Images');
        
        // 创建multipart请求
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudflare.com/client/v4/accounts/$cfAccountId/images/v1'),
        );
        
        // 添加认证头
        request.headers['Authorization'] = 'Bearer $cfApiToken';
        
        // 添加图片文件
        final filename = 'ai_generated_${DateTime.now().millisecondsSinceEpoch}.png';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: filename,
            contentType: MediaType('image', 'png'),
          ),
        );
        
        // 发送请求
        final cfResponse = await request.send();
        final cfResponseBody = await cfResponse.stream.bytesToString();
        
        if (cfResponse.statusCode != 200) {
          debugPrint('Cloudflare上传失败: ${cfResponse.statusCode}');
          debugPrint('Cloudflare响应内容: $cfResponseBody');
          throw Exception('图片上传失败');
        }
        
        // 解析Cloudflare响应
        final cfData = json.decode(cfResponseBody);
        if (cfData['success'] != true || cfData['result'] == null) {
          debugPrint('Cloudflare响应解析失败: $cfResponseBody');
          throw Exception('图片上传响应解析失败');
        }
        
        // 5. 获取Cloudflare图片URL并格式化为shipian.app域名
        String imageUrl = cfData['result']['variants'][0];
        debugPrint('Cloudflare返回的图片URL: $imageUrl');
        
        // 格式化为shipian.app域名
        final formattedUrl = _formatImageUrl(imageUrl);
        debugPrint('格式化后的图片URL: $formattedUrl');
        
        // 6. 返回成功响应，包含图片URL
        final successResponse = http.Response(
          jsonEncode({
            'success': true,
            'preview_url': formattedUrl,
            'message': '预览生成成功'
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        return successResponse;
      } catch (frontendError) {
        debugPrint('前端生成预览失败: $frontendError');
        
        // 如果前端生成失败，返回错误响应
        final errorResponse = http.Response(
          jsonEncode({
            'success': false,
            'error': '预览生成失败: $frontendError',
            'message': '预览生成失败'
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
        
        return errorResponse;
      }
    } catch (e) {
      debugPrint('生成预览异常: $e');
      
      // 如果发生异常，返回一个错误响应
      final errorResponse = http.Response(
        jsonEncode({
          'success': false,
          'error': e.toString(),
          'message': '预览生成失败'
        }),
        500,
        headers: {'content-type': 'application/json'},
      );
      
      return errorResponse;
    }
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
