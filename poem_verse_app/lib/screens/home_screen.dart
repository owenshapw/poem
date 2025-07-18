// lib/screens/home_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';
import 'package:poem_verse_app/screens/poem_magazine_screen.dart';

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
        final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
        articleProvider.fetchArticles();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (mounted) {
          final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF232946),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFF232946),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Consumer<ArticleProvider>(
              builder: (context, articleProvider, child) {
                if (articleProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor),
                    ),
                  );
                }

                if (articleProvider.errorMessage != null) {
                  return Center(
                    child: Text(
                      articleProvider.errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                if (articleProvider.articles.isEmpty && articleProvider.topArticle == null) {
                  return const Center(
                    child: Text(
                      'No articles found.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 48),
                  itemCount: articleProvider.articles.length +
                      (articleProvider.topArticle != null ? 1 : 0) +
                      (articleProvider.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (articleProvider.topArticle != null) {
                      if (index == 0) {
                        return _buildTopArticleCard(
                            context, articleProvider.topArticle!);
                      }
                      index -= 1;
                    }

                    if (index == articleProvider.articles.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final article = articleProvider.articles[index];
                    return _buildWeekCard(
                        context, article, index, articleProvider.articles);
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 56,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                  tooltip: '杂志风格Demo',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PoemMagazineScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                  tooltip: '登录',
                  onPressed: () {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArticleCard(BuildContext context, Article article) {
    String content = article.content;
    List<String> lines = content.split('\n');
    String previewText = lines.take(1).join('\n');

    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                articles: [article],
                initialIndex: 0,
              ),
            ),
          ).then((_) {
            if (!mounted) return;
            Provider.of<ArticleProvider>(context, listen: false)
                .fetchArticles();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('打开文章失败: $e')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: SimpleNetworkImage(
                  imageUrl:
                      ApiService.getImageUrlWithVariant(article.imageUrl, 'public'),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      previewText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, Article article, int index,
      List<Article> articles) {
    String content = article.content;
    List<String> lines = content.split('\n');
    String previewText = lines.take(3).join('\n');
    
    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                articles: articles,
                initialIndex: index,
              ),
            ),
          ).then((_) {
            if (!mounted) return;
            Provider.of<ArticleProvider>(context, listen: false)
                .fetchArticles();
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('打开文章失败: $e')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: article.imageUrl.isNotEmpty
                  ? SimpleNetworkImage(
                      imageUrl:
                          ApiService.getImageUrlWithVariant(article.imageUrl, 'list'),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: 56,
                        height: 56,
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(Icons.image_outlined,
                            color: Colors.white.withOpacity(0.3), size: 28),
                      ),
                      errorWidget: Container(
                        width: 56,
                        height: 56,
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.white.withOpacity(0.3), size: 28),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(Icons.image_outlined,
                          color: Colors.white.withOpacity(0.3), size: 28),
                    ),
            ),
          ),
          title: Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.author,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                previewText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}