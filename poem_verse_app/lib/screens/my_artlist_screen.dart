import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MyArtlistScreen extends StatefulWidget {
  const MyArtlistScreen({super.key});
  @override
  State<MyArtlistScreen> createState() => _MyArtlistScreenState();
}

class _MyArtlistScreenState extends State<MyArtlistScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Article> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;
      if (token == null || userId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }
      final data = await ApiService.getMyArticles(token, userId);
      final articlesJson = data['articles'] as List?;
      final articles = articlesJson?.map((json) => Article.fromJson(json)).toList() ?? <Article>[];
      setState(() {
        _articles = articles;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('极致平滑卡片列表')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _articles.length,
                    cacheExtent: 800,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return _ArticleCard(
                        article: article,
                        onTap: () {}, // 可集成详情页
                      );
                    },
                  ),
                ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: 200,
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF3EAFB),
                  height: 200,
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.purple[100],
                    size: 32,
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 400),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Text(
                article.title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 