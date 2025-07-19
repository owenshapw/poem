// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  MyArticlesScreenState createState() => MyArticlesScreenState();
}

class MyArticlesScreenState extends State<MyArticlesScreen> {
  Future<List<Article>>? _myArticlesFuture;
  final ScrollController _scrollController = ScrollController();
  int _lastViewedIndex = 0;  // 记录最后查看的文章索引
  final double _itemHeight = 370.0;  // 估计的每个文章卡片高度（包括间距）

  @override
  void initState() {
    super.initState();
    _loadMyArticles();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // 滚动到指定索引位置
  void _scrollToIndex(int index) {
    // 确保在下一帧执行，以确保布局已完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (_scrollController.hasClients) {
        // 确保索引有效
        if (index < 0) {
          return;
        }
        
        try {
          // 使用类成员变量而不是局部变量，确保一致性
          // 计算目标位置，考虑顶部偏移
          final double topOffset = 0.0; // 不考虑顶部偏移
          final double position = (index * _itemHeight) - topOffset;
          final double safePosition = position < 0 ? 0.0 : position;
          
          // 直接跳转到目标位置，不使用动画
          _scrollController.jumpTo(safePosition);
        } catch (e) {
          debugPrint('滚动到指定位置失败: $e');
        }
      }
    });
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
      appBar: AppBar(
        title: const Text('我的诗篇'),
      ),
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
    // 用于平滑加载体验
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _myArticlesFuture == null
          ? Center(
              key: const ValueKey('loading'),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade100),
              ),
            )
          : FutureBuilder<List<Article>>(
              key: const ValueKey('future'),
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
            ),
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
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          // 使用RepaintBoundary包装每个卡片，减少重绘
          return RepaintBoundary(
            child: _buildArticleCard(articles, article, index),
          );
        },
        // 使用更平滑的滚动物理效果
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        cacheExtent: 800, // 预加载3-4屏
      ),
    );
  }

  Widget _buildArticleCard(List<Article> articles, Article article, int index) {
    // 预处理文本内容，避免在构建过程中进行
    final String previewText = _getPreviewText(article.content);
    
    // 使用ValueKey确保卡片有唯一标识，优化重建
    return GestureDetector(
      key: ValueKey(article.id),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArticleDetailScreen(articles: articles, initialIndex: index),
          ),
        );
        
        if (mounted) {
          // 处理可能的文章变更和最后查看的位置
          if (result != null && result is Map) {
            // 获取最后查看的文章ID
            final String? lastViewedId = result['lastViewedArticleId'] as String?;
            
            if (lastViewedId != null) {
              // 查找最后查看的文章在列表中的索引
              final lastIndex = articles.indexWhere((a) => a.id == lastViewedId);
              if (lastIndex != -1) {
                _lastViewedIndex = lastIndex;
                
                // 滚动到最后查看的文章位置
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(_lastViewedIndex);
                });
              }
            }
            
            // 处理文章变更
            final id = result['articleId'];
            final changed = result['changed'] ?? false;
            if (id != null && changed) {
              final newIndex = articles.indexWhere((a) => a.id == id);
              if (newIndex != -1) {
                setState(() {}); // 只在有变更时局部刷新
              }
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // 使用withAlpha替代withOpacity以提高性能
              color: Colors.purple.withAlpha(15),
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
              child: Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFF3EAFB), // 预设背景色，避免闪烁
                child: CachedNetworkImage(
                  imageUrl: ApiService.buildImageUrl(article.imageUrl),
                  fit: BoxFit.cover,
                  // 使用固定尺寸的占位符，避免尺寸变化导致的布局跳跃
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE1BEE7), // 使用固定颜色代替Colors.purple[100]
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFFE1BEE7), // 使用固定颜色代替Colors.purple[100]
                      size: 32,
                    ),
                  ),
                  // 减少动画时间，避免长时间的过渡效果
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 50),
                  // 优化内存缓存设置
                  memCacheHeight: (200 * MediaQuery.of(context).devicePixelRatio).toInt(),
                  memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                article.author,
                style: const TextStyle(
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
                style: const TextStyle(
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
  
  // 提取预览文本的辅助方法，避免在构建过程中重复计算
  String _getPreviewText(String content) {
    final lines = content.split('\n');
    return lines.take(3).join('\n');
  }

  // 移除有问题的didChangeDependencies方法，避免滚动冲突
}
