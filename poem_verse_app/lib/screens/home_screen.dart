// lib/screens/home_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
// 已删除不需要的导入

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 使用Future.microtask延迟执行，避免在构建过程中调用setState
    Future.microtask(() {
      if (mounted) {
        final articleProvider = Provider.of<ArticleProvider>(
          context,
          listen: false,
        );
        articleProvider.fetchArticles();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (mounted) {
          final articleProvider = Provider.of<ArticleProvider>(
            context,
            listen: false,
          );
          articleProvider.fetchMoreArticles();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              // 使用图标代替缺失的图片资源
              backgroundColor: Colors.purple,
              radius: 14,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            tooltip: '登录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my-articles');
              },
              child: const Text('我的诗篇'),
            ),
          ],
        ),
      ),
    );
  }

  // 已删除未使用的方法
}
