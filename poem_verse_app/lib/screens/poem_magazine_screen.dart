// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/article.dart';
import '../widgets/poem_magazine_view.dart';
import '../api/api_service.dart';

class PoemMagazineScreen extends StatefulWidget {
  const PoemMagazineScreen({super.key});

  @override
  State<PoemMagazineScreen> createState() => _PoemMagazineScreenState();
}

class _PoemMagazineScreenState extends State<PoemMagazineScreen> {
  late Future<List<Article>> _articlesFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<bool> _expandedList = [];

  @override
  void initState() {
    super.initState();
    _articlesFuture = ApiService.fetchArticles(page: 1, perPage: 100);
  }

  void _initExpandedList(int length) {
    if (_expandedList.length != length) {
      _expandedList = List.filled(length, false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxCardHeight = MediaQuery.of(context).size.height * 0.75;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FF),
        elevation: 0,
        title: const Text('诗篇'),
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: \n${snapshot.error}'));
          }
          final articles = snapshot.data ?? [];
          _initExpandedList(articles.length);
          if (articles.isEmpty) {
            return const Center(child: Text('暂无文章'));
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: articles.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: maxCardHeight,
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = ((_pageController.page ?? _pageController.initialPage).toDouble()) - index.toDouble();
                              value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                            }
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: value,
                                child: Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12 * value),
                                            blurRadius: 24 * value,
                                            spreadRadius: 2 * value,
                                            offset: Offset(0, 8 * value),
                                          ),
                                        ],
                                      ),
                                      child: PoemMagazineView(
                                        title: articles[index].title,
                                        author: articles[index].author,
                                        contentLines: articles[index].content.split('\n'),
                                        isExpanded: _expandedList[index],
                                        onExpandToggle: () {
                                          setState(() {
                                            _expandedList[index] = !_expandedList[index];
                                          });
                                        },
                                        comment: null,
                                        imageUrl: articles[index].imageUrl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '第 ${_currentPage + 1} / ${articles.length} 篇',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 