import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class NetworkImageWithDio extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Map<String, String>? headers;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useFallback; // 新增：是否使用回退方案

  const NetworkImageWithDio({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.headers,
    this.placeholder,
    this.errorWidget,
    this.useFallback = true, // 默认启用回退
  });

  @override
  NetworkImageWithDioState createState() => NetworkImageWithDioState();
}

class NetworkImageWithDioState extends State<NetworkImageWithDio> {
  late Future<Uint8List?> _imageFuture;
  int _retryCount = 0;
  static const int maxRetries = 2;
  bool _useFallback = false; // 是否使用回退方案

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(NetworkImageWithDio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _retryCount = 0;
      _useFallback = false;
      _imageFuture = _loadImage();
    }
  }

  Future<Uint8List?> _loadImage() async {
    
    final dio = Dio();
    
    // 配置超时
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient(context: SecurityContext.defaultContext);
      client.connectionTimeout = const Duration(seconds: 10);
      return client;
    };

    try {
      final response = await dio.get(
        widget.imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Accept-Language': 'en-US,en;q=0.9',
            'Connection': 'keep-alive',
            ...?widget.headers,
          },
        ),
      );
      
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      
      // 如果是403错误或其他网络错误，尝试重试
      if (_retryCount < maxRetries && 
          (e.toString().contains('403') || 
           e.toString().contains('Connection reset') ||
           e.toString().contains('timeout'))) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        return _loadImage();
      }
      
      // 如果启用了回退方案，标记使用回退
      if (widget.useFallback) {
        _useFallback = true;
        return null;
      }
      
      // 最终失败，返回null
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double? safeDouble(double? v) => (v == null || v.isNaN) ? null : v;
    // 如果启用了回退方案且Dio失败，使用Flutter内置的Image.network
    if (_useFallback && widget.useFallback) {
      return Image.network(
        widget.imageUrl,
        width: safeDouble(widget.width),
        height: safeDouble(widget.height),
        fit: widget.fit,
        headers: widget.headers,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: widget.placeholder ?? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null && 
                           loadingProgress.expectedTotalBytes! > 0
                        ? (loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!).clamp(0.0, 1.0)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加载中...\n${widget.imageUrl}',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: safeDouble(widget.width),
            height: safeDouble(widget.height),
            color: Colors.grey[200],
            child: widget.placeholder ?? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加载中...\n${widget.imageUrl}',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        // 加载成功
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            width: safeDouble(widget.width),
            height: safeDouble(widget.height),
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
        }
        
        // 加载失败
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: widget.errorWidget ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '图片加载失败\n${widget.imageUrl}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
