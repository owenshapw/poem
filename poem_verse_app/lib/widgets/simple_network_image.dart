import 'package:flutter/material.dart';

class SimpleNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SimpleNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  double? safeDouble(double? v) => (v == null || v.isNaN) ? null : v;

  @override
  Widget build(BuildContext context) {
    
    return Image.network(
      imageUrl,
      width: safeDouble(width),
      height: safeDouble(height),
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          width: safeDouble(width),
          height: safeDouble(height),
          color: Colors.grey[200],
          child: placeholder ?? Center(
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
                  '加载中...\n$imageUrl',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: safeDouble(width),
          height: safeDouble(height),
          color: Colors.grey[200],
          child: errorWidget ?? Center(
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
                  '图片加载失败\n$imageUrl',
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
      },
    );
  }
} 