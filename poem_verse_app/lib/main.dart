// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/home_screen.dart';
import 'package:poem_verse_app/screens/reset_password_screen.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/screens/test_login_screen.dart';
import 'package:poem_verse_app/screens/my_articles_screen.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启用调试信息
  if (kDebugMode) {
    debugPrint('应用启动中...');
  }

  // 使用正常的动画时间，但添加错误处理
  timeDilation = 1.0; // 正常动画速度
  
  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 打印更详细的错误信息
    debugPrint('Flutter错误: ${details.exception}');
    debugPrint('堆栈跟踪: ${details.stack}');
  };
  
  // 加载环境变量
  await dotenv.load(fileName: ".env");
  
  // 初始化 Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  runApp(const PoemVerseApp());
}

class PoemVerseApp extends StatelessWidget {
  const PoemVerseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
      ],
      child: Builder(
        builder: (context) {
          // 添加全局错误处理
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                '出现错误，请重试',
                style: TextStyle(color: Colors.red),
              ),
            );
          };
          
          return MaterialApp(
            title: 'PoemVerse',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              // 使用默认的页面过渡动画，提供更流畅的体验
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                },
              ),
            ),
            // 使用HomeScreen作为初始页面
            initialRoute: '/home',
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/test-login': (context) => const TestLoginScreen(),
              '/my-articles': (context) => const MyArticlesScreen(),
              // '/migration' 路由和 MigrationScreen 相关内容已移除
            },
            onGenerateRoute: (settings) {
              if (settings.name != null) {
                // 处理密码重置链接
                if (settings.name!.startsWith('/reset-password')) {
                  final uri = Uri.parse(settings.name!);
                  final token = uri.queryParameters['token'];
                  if (token != null) {
                    return MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen(token: token),
                    );
                  }
                }
                
                // 处理文章详情页直接启动
                if (settings.name!.startsWith('/article/')) {
                  // 从路径中提取文章ID
                  final articleId = settings.name!.substring('/article/'.length);
                  if (articleId.isNotEmpty) {
                    // 加载文章并导航到详情页
                    return MaterialPageRoute(
                      builder: (context) => FutureBuilder<Article>(
                        future: ApiService.getArticleDetail(articleId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Scaffold(
                              appBar: AppBar(title: const Text('错误')),
                              body: Center(
                                child: Text('无法加载文章: ${snapshot.error ?? "未找到"}'),
                              ),
                            );
                          }
                          
                          // 成功加载文章，显示详情页
                          return ArticleDetailScreen(
                            articles: [snapshot.data!],
                            initialIndex: 0,
                          );
                        },
                      ),
                    );
                  }
                }
              }
              return null;
            },
            // 添加全局构建器，确保所有MediaQuery值都是有限的
            builder: (context, child) {
              // 确保child不为null
              if (child == null) {
                return const SizedBox.shrink();
              }
              
              // 添加全局字体缩放因子限制，避免极端值
              return MediaQuery(
                // 限制文本缩放比例，避免极端值导致布局问题
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0), // 固定文本缩放因子为1.0
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio.isFinite 
                      ? MediaQuery.of(context).devicePixelRatio 
                      : 1.0, // 确保设备像素比是有限值
                ),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
