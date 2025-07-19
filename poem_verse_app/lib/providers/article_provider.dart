// lib/providers/article_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'dart:developer' as developer;

class ArticleProvider with ChangeNotifier {
  List<Article> _articles = [];
  Article? _topArticle;
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<Article> get articles => _articles;
  Article? get topArticle => _topArticle;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchArticles([String? token]) async {
    _isLoading = true;
    _page = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final articlesData = await ApiService.fetchHomeArticles();
      developer.log('API Response: ${jsonEncode(articlesData)}', name: 'ArticleProvider');

      final articlesList = articlesData['articles'] as List?;
      final newArticles = articlesList
          ?.map((data) => Article.fromJson(data))
          .toList() ?? [];
      
      if (newArticles.isNotEmpty) {
        _topArticle = newArticles.first;
        _articles = newArticles.sublist(1);
      } else {
        _topArticle = null;
        _articles = [];
      }

      developer.log('Processed Articles Count: ${_articles.length}', name: 'ArticleProvider');
      developer.log('Top Article: ${_topArticle?.title}', name: 'ArticleProvider');

    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load articles. Please try again.';
      developer.log('Error fetching articles: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
      _articles = [];
      _topArticle = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreArticles() async {
    if (_isLoading || !_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _page++;
    try {
      final newArticles = await ApiService.fetchArticles(page: _page);
      if (newArticles.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(newArticles);
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching more articles: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createArticle(String token, String title, String content, List<String> tags, String author, {String? previewImageUrl}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 检查token是否有效
      if (token.isEmpty) {
        throw Exception('认证令牌无效，请重新登录');
      }
      
      developer.log('开始创建文章: $title', name: 'ArticleProvider');
      final newArticle = await ApiService.createArticle(token, title, content, tags, author, previewImageUrl: previewImageUrl);

      _isLoading = false;
      
      if (newArticle != null) {
        // Add the new article to the beginning of the list
        _articles.insert(0, newArticle);
        developer.log('文章创建成功: ${newArticle.id}', name: 'ArticleProvider');
        notifyListeners();
        return true;
      } else {
        developer.log('文章创建失败: 返回null', name: 'ArticleProvider');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      developer.log('文章创建异常: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
      _isLoading = false;
      _errorMessage = '创建文章失败: $e';
      notifyListeners();
      rethrow; // 重新抛出异常，让UI层处理
    }
  }

  Future<String?> generateImage(String token, String articleId) async {
    final response = await ApiService.generateImage(token, articleId);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['image_url'];
    } else {
      return null;
    }
  }

  Future<String?> generatePreview(String token, String title, String content, List<String> tags, String author) async {
    try {
      // 检查token是否有效
      if (token.isEmpty) {
        throw Exception('认证令牌无效，请重新登录');
      }
      
      developer.log('开始生成预览: $title', name: 'ArticleProvider');
      final response = await ApiService.generatePreview(token, title, content, tags, author);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final previewUrl = data['preview_url'];
        developer.log('预览生成成功: $previewUrl', name: 'ArticleProvider');
        return previewUrl;
      } else {
        // 尝试解析错误信息
        String errorMessage = '生成预览失败: 状态码 ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // 解析错误信息失败，使用默认错误信息
        }
        developer.log('预览生成失败: $errorMessage', name: 'ArticleProvider');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      developer.log('预览生成异常: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
      _errorMessage = '生成预览失败: $e';
      notifyListeners();
      return null; // 返回null，让UI层处理
    }
  }

  Future<void> updateArticle(String token, String articleId, String title, String content, List<String> tags, String author, {String? previewImageUrl}) async {
    try {
      await deleteArticle(token, articleId);
      await createArticle(token, title, content, tags, author, previewImageUrl: previewImageUrl);
    } catch (e) {
      throw Exception('编辑失败: $e');
    }
  }

  Future<void> refreshAllData(String token) async {
    await fetchArticles(token);
  }

  Future<void> deleteArticle(String token, String articleId) async {
    final response = await ApiService.deleteArticle(token, articleId);
    
    if (response.statusCode == 200) {
      await fetchArticles(token);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? '删除失败');
    }
  }
}