// lib/screens/create_article_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/network_image_with_dio.dart';

class CreateArticleScreen extends StatefulWidget {
  final Article? article;
  final bool isEdit;
  const CreateArticleScreen({super.key, this.article, this.isEdit = false});

  @override
  CreateArticleScreenState createState() => CreateArticleScreenState();
}

class CreateArticleScreenState extends State<CreateArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _tags = [];
  String? _previewImageUrl;
  bool _isGeneratingPreview = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.article != null) {
      _titleController.text = widget.article!.title;
      _contentController.text = widget.article!.content;
      _tags.clear();
      _tags.addAll(widget.article!.tags);
      _previewImageUrl = widget.article!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _generatePreview() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先填写标题和内容')),
      );
      return;
    }
    setState(() {
      _isGeneratingPreview = true;
    });
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;
    final title = _titleController.text;
    final content = _contentController.text;
    final tags = List<String>.from(_tags);
    final author = authProvider.username ?? '佚名';
    final previewUrl = await articleProvider.generatePreview(
      token, title, content, tags, author,
    );
    if (!mounted) return;
    setState(() {
      _previewImageUrl = previewUrl;
      _isGeneratingPreview = false;
    });
    if (previewUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片生成成功！')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片生成失败')),
      );
    }
  }

  void _regeneratePreview() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先填写标题和内容')),
      );
      return;
    }
    setState(() {
      _isGeneratingPreview = true;
    });
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token!;
    final title = _titleController.text;
    final content = _contentController.text;
    final tags = List<String>.from(_tags);
    final author = authProvider.username ?? '佚名';
    final previewUrl = await articleProvider.generatePreview(
      token, title, content, tags, author,
    );
    if (!mounted) return;
    setState(() {
      _previewImageUrl = previewUrl;
      _isGeneratingPreview = false;
    });
    if (previewUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片重新生成成功！')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片重新生成失���')),
      );
    }
  }

  String _buildImageUrl(String imageUrl) {
    return AppConfig.buildImageUrl(imageUrl);
  }

  void _createOrUpdateArticle() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写标题和内容')),
      );
      return;
    }
    setState(() {
      _isCreating = true;
    });
    
    try {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 安全地获取token
      final token = authProvider.token;
      if (token == null) {
        throw Exception('用户未登录或登录已过期，请重新登录');
      }
      final author = authProvider.username ?? '佚名';

      final title = _titleController.text;
      final content = _contentController.text;
      final tags = List<String>.from(_tags);
      final previewImageUrl = _previewImageUrl;
      
      
      if (widget.isEdit && widget.article != null) {
        // 编辑模式，调用更新接口
        await articleProvider.updateArticle(
          token, widget.article!.id, title, content, tags, author, previewImageUrl: previewImageUrl,
        );
        
        // 刷新所有相关数据
        await articleProvider.refreshAllData(token);
      } else {
        // 新建
        await articleProvider.createArticle(
          token, title, content, tags, author, previewImageUrl: previewImageUrl,
        );
        
        // 刷新所有相关数据
        await articleProvider.refreshAllData(token);
      }
      
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发布失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑诗篇' : '发布诗篇'),
        actions: [
          if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.preview),
              onPressed: _isGeneratingPreview ? null : _generatePreview,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            SizedBox(height: 16),
            
            // 标签输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: Text('添加'),
                ),
              ],
            ),
            
            // 标签显示
            if (_tags.isNotEmpty) ...[
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
            ],
            
            SizedBox(height: 16),
            
            // 预览图片
            if (_previewImageUrl != null) ...[
              Text('预览效果:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetworkImageWithDio(
                    imageUrl: _buildImageUrl(_previewImageUrl!),
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
              ),
              SizedBox(height: 8),
              // 重新生成按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPreview ? null : _regeneratePreview,
                      icon: _isGeneratingPreview 
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.refresh),
                      label: Text(_isGeneratingPreview ? '重新生成中...' : '重新生成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _previewImageUrl = null;
                        });
                      },
                      icon: Icon(Icons.delete),
                      label: Text('删除预览'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
            
            // 生成预览按钮
            if (_previewImageUrl == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPreview ? null : _generatePreview,
                  icon: _isGeneratingPreview 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.preview),
                  label: Text(_isGeneratingPreview ? '生成中...' : '生成预览'),
                ),
              ),
            
            SizedBox(height: 16),
            
            // 发布按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createOrUpdateArticle,
                icon: _isCreating 
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send),
                label: Text(_isCreating ? '发布中...' : '发布诗篇'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
