import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';

class UserArticlesScreen extends StatefulWidget {
  const UserArticlesScreen({super.key});

  @override
  State<UserArticlesScreen> createState() => _UserArticlesScreenState();
}

class _UserArticlesScreenState extends State<UserArticlesScreen> {
  List<Article> _userArticles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserArticles();
  }

  Future<void> _loadUserArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getValidToken();
      final userId = authProvider.userId;

      if (token == null || userId == null) {
        setState(() {
          _errorMessage = '请先登录';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.getMyArticles(token, userId);
      if (response.containsKey('articles')) {
        final articlesList = response['articles'] as List;
        setState(() {
          _userArticles = articlesList.map((data) => Article.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '获取文章失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载文章时出错: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的文章'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _userArticles.isEmpty
                  ? const Center(child: Text('暂无文章'))
                  : RefreshIndicator(
                      onRefresh: _loadUserArticles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _userArticles.length,
                        itemBuilder: (context, index) {
                          final article = _userArticles[index];
                          return _buildArticleCard(context, article, index);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加新文章的逻辑
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建新文章功能即将推出')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: article.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SimpleNetworkImage(
                  imageUrl: ApiService.getImageUrlWithVariant(article.imageUrl, 'list'),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
        title: Text(
          article.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          article.content.split('\n').first,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                articles: [article],
                initialIndex: 0,
              ),
            ),
          ).then((_) {
            if (mounted) {
              _loadUserArticles();
            }
          });
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              _deleteArticle(article.id);
            } else if (value == 'edit') {
              // 编辑文章的逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('编辑功能即将推出')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteArticle(String articleId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getValidToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先登录')),
          );
        }
        return;
      }

      // 显示确认对话框
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这篇文章吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final response = await ApiService.deleteArticle(token, articleId);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文章已删除')),
          );
        }
        _loadUserArticles(); // 重新加载文章列表
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除文章时出错: $e')),
        );
      }
    }
  }
}