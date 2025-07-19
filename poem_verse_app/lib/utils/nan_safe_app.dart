import 'package:flutter/material.dart';

/// 一个安全的MaterialApp包装器，用于防止NaN错误
class NanSafeApp extends StatelessWidget {
  final String title;
  final ThemeData? theme;
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;
  final RouteFactory? onGenerateRoute;
  final List<NavigatorObserver>? navigatorObservers;

  const NanSafeApp({
    super.key,
    required this.title,
    this.theme,
    required this.initialRoute,
    required this.routes,
    this.onGenerateRoute,
    this.navigatorObservers,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: theme,
      initialRoute: initialRoute,
      routes: routes,
      onGenerateRoute: onGenerateRoute,
      navigatorObservers: navigatorObservers ?? [],
      // 添加全局错误处理
      builder: (context, child) {
        // 添加错误边界
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Text('出现错误，请重试', style: TextStyle(color: Colors.red)),
          );
        };

        // 确保child不为null
        if (child == null) {
          return const SizedBox.shrink();
        }

        // 添加全局字体缩放因子限制，避免极端值
        return MediaQuery(
          // 限制文本缩放比例，避免极端值导致布局问题
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // 固定文本缩放因子为1.0
            devicePixelRatio: MediaQuery.of(context).devicePixelRatio.isFinite
                ? MediaQuery.of(context).devicePixelRatio
                : 1.0, // 确保设备像素比是有限值
          ),
          child: child,
        );
      },
    );
  }
}

/// 安全的数值处理工具
class SafeValues {
  /// 确保double值是有限的，如果不是则返回默认值
  static double ensureFinite(double? value, {double defaultValue = 0.0}) {
    if (value == null || value.isNaN || value.isInfinite) {
      return defaultValue;
    }
    return value;
  }

  /// 确保int值是有限的，如果不是则返回默认值
  static int ensureFiniteInt(int? value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    }
    return value;
  }

  /// 安全地计算宽度，避免NaN和无限值
  static double safeWidth(BuildContext context, {double defaultValue = 300.0}) {
    final width = MediaQuery.of(context).size.width;
    return ensureFinite(width, defaultValue: defaultValue);
  }

  /// 安全地计算高度，避免NaN和无限值
  static double safeHeight(
    BuildContext context, {
    double defaultValue = 500.0,
  }) {
    final height = MediaQuery.of(context).size.height;
    return ensureFinite(height, defaultValue: defaultValue);
  }
}

double? safeDouble(double? v) =>
    (v == null || v.isNaN || v.isInfinite) ? null : v;
