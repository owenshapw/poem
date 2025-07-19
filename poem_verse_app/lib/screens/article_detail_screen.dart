// lib/screens/article_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/widgets/network_image_with_dio.dart';

class ArticleDetailScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleDetailScreen({super.key, required this.articles, required this.initialIndex});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late PageController _pageController;
  late Article _article;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _article = widget.articles[widget.initialIndex];
  }

  @override
  void dispose() {
    // 只释放资源，不返回数据（由WillPopScope处理）
    _pageController.dispose();
    super.dispose();
  }

  bool _isAuthor(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId == _article.userId;
  }

  Future<void> _deleteArticle() async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final token = authProvider.token!;
      final articleId = _article.id;

      final confirmed = await _showDeleteConfirmDialog();
      if (confirmed != true) {
        setState(() {
          _isDeleting = false;
        });
        return;
      }

      if (mounted) {
        _showLoadingDialog();
      }

      await articleProvider.deleteArticle(token, articleId);
      
      if (mounted) {
        _hideLoadingDialog();
        _showSuccessMessage('诗篇删除成功');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorMessage('删除失败：${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这篇诗篇吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _shareArticle() {
    final shareText = '''
${_article.title}

作者：${_article.author}
发布时间：${_formatDate(_article.createdAt)}

${_article.content}

${_article.tags.isNotEmpty ? '标签：${_article.tags.join('、')}' : ''}

来自诗篇App
''';
    
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _editArticle() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateArticleScreen(
          article: _article,
          isEdit: true,
        ),
      ),
    );
    
    if (updated == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 在用户点击返回按钮或使用手势返回时，返回最后查看的文章ID
        final Map<String, dynamic> result = {
          'articleId': _article.id, 
          'changed': _isDeleting,
          'lastViewedArticleId': _article.id,
        };
        
        debugPrint('用户返回，传递数据: $result');
        Navigator.of(context).pop(result);
        return false; // 返回false，因为我们已经手动处理了返回操作
      },
      child: Scaffold(
        appBar: AppBar(
        title: const Text('诗篇详情'),
        actions: [
          if (_isAuthor(context)) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
              onPressed: _isDeleting ? null : _editArticle,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black87),
              tooltip: '删除',
              onPressed: _isDeleting ? null : _deleteArticle,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
            onPressed: _shareArticle,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.articles.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _article = widget.articles[index];
            debugPrint('页面切换到索引: $index, 文章ID: ${_article.id}, 标题: ${_article.title}');
          });
        },
        itemBuilder: (context, index) {
          final article = widget.articles[index];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 260,
                    child: NetworkImageWithDio(
                      imageUrl: ApiService.buildImageUrl(article.imageUrl),
                      fit: BoxFit.cover,
                      placeholder: Container(color: Colors.white),
                      errorWidget: Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                              Text('图片加载失败'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '作者：${article.author}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '发布时间：${_formatDate(article.createdAt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (article.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: article.tags.map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Divider(),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withOpacity(0.1)),
                        ),
                        child: Text(
                          article.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('点赞功能开发中...')),
                                );
                              },
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('点赞'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('收藏功能开发中...')),
                                );
                              },
                              icon: const Icon(Icons.bookmark_border),
                              label: const Text('收藏'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}