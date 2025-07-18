// lib/models/article.dart
class Article {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String author;
  final String imageUrl;
  final String createdAt;
  final String userId;
  final int? likeCount;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.author,
    required this.imageUrl,
    required this.createdAt,
    required this.userId,
    this.likeCount,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      author: json['author'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      likeCount: json['like_count'] ?? json['likeCount'],
    );
  }
}
