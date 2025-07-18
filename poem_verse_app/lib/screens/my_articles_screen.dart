// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:poem_verse_app/widgets/network_image_with_dio.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  MyArticlesScreenState createState() => MyArticlesScreenState();
}

class MyArticlesScreenState extends State<MyArticlesScreen> {
  Future<List<Article>>? _myArticlesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMyArticles();
  }

  Future<void> _loadMyArticles() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) {
      // Handle not logged in state
      setState(() {
        _myArticlesFuture = Future.value([]); // Return empty list
      });
      return;
    }

    setState(() {
      _myArticlesFuture = ApiService.getMyArticles(token, userId).then((data) {
        final articlesJson = data['articles'] as List?;
        return articlesJson?.map((json) => Article.fromJson(json)).toList().cast<Article>() ??
            <Article>[];
      }).catchError((error) {
        debugPrint('加载我的文章失败: $error');
        // 返回空列表而不是抛出错误
        return <Article>[];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 22.0;
    final titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.grey[900],
      letterSpacing: 1.2,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: iconSize + 8,
                        child: Text('我的诗篇', style: titleStyle),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: iconSize,
                          color: Colors.grey[800],
                        ),
                        tooltip: '发布诗篇',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateArticleScreen(),
                            ),
                          );

                          if (result == true) {
                            _loadMyArticles();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout_outlined,
                          size: iconSize,
                          color: Colors.grey[800],
                        ),
                        tooltip: '退出登录',
                        onPressed: () async {
                          // 存储必要的引用
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final navigator = Navigator.of(context);

                          // 显示确认对话框
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认退出'),
                              content: const Text('确定要退出登录吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('退出'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          // 执行退出登录
                          await authProvider.logout();

                          // 导航到登录页面
                          if (mounted) {
                            navigator.pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false, // 清除所有路由
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<Article>>(
      future: _myArticlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade100),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final articles = snapshot.data!;
        if (articles.isEmpty) {
          return _buildEmptyState();
        }

        return _buildArticlesGrid(articles);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.black54, size: 64),
          SizedBox(height: 16),
          Text('加载失败', style: TextStyle(color: Colors.black87, fontSize: 18)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMyArticles,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            color: Colors.purple.shade200,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            '还没有诗篇',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右上角的编辑按钮\n开始创作你的第一首诗篇',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateArticleScreen(),
                ),
              );
              if (result == true) {
                _loadMyArticles();
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('开始创作'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade100,
              foregroundColor: Colors.purple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesGrid(List<Article> articles) {
    return RefreshIndicator(
      onRefresh: _loadMyArticles,
      color: Colors.white,
      backgroundColor: Colors.transparent,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildArticleCard(articles, article, index);
        },
      ),
    );
  }

  Widget _buildArticleCard(List<Article> articles, Article article, int index) {
    String content = article.content;
    List<String> lines = content.split('\n');
    String previewText = lines.take(3).join('\n');
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArticleDetailScreen(articles: articles, initialIndex: index),
          ),
        );
        // From detail screen, we might need to refresh as well
        _loadMyArticles();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: article.imageUrl.isNotEmpty
                      ? NetworkImageWithDio(
                          imageUrl: ApiService.buildImageUrl(article.imageUrl),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 200,
                          color: const Color(0xFFF3EAFB),
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.purple[100],
                            size: 32,
                          ),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                article.title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                article.author,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Text(
                previewText,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
