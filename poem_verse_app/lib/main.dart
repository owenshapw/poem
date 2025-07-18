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
import 'package:poem_verse_app/screens/migration_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启用调试信息
  if (kDebugMode) {
    debugPrint('应用启动中...');
  }

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
      child: MaterialApp(
        title: 'PoemVerse',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // 使用LoginScreen作为初始页面，方便测试
        initialRoute: '/login',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/test-login': (context) => const TestLoginScreen(),
          '/my-articles': (context) => const MyArticlesScreen(),
          '/migration': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final email = args?['email'] as String? ?? '';
            return MigrationScreen(email: email);
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/reset-password')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'];
            if (token != null) {
              return MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(token: token),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
