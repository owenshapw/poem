import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poem_verse_app/config/app_config.dart';

/// 极简版迁移对话框，避免任何可能导致NaN错误的复杂布局
class MigrationDialog extends StatelessWidget {
  final String email;
  final String message;

  const MigrationDialog({
    super.key,
    required this.email,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // 使用最简单的布局，避免任何可能导致NaN错误的复杂计算
    // 使用AlertDialog而不是Dialog，它有更好的内置布局处理
    return AlertDialog(
      title: const Text('账户安全升级'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            // 消息
            Text(message),
            const SizedBox(height: 12),
            
            // 好处列表 - 使用简单的列表而不是复杂布局
            const Text('升级好处:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('• 更强的账户安全保护'),
            const Text('• 支持邮箱验证'),
            const Text('• 更安全的密码管理'),
            const SizedBox(height: 4),
            const Text('您的所有文章和评论都将保留。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后再说'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _openMigrationPage(email);
          },
          child: const Text('立即升级'),
        ),
      ],
    );
  }

  void _openMigrationPage(String email) async {
    try {
      // 使用migration-page端点，这是一个GET端点
      final urlString = '${AppConfig.backendBaseUrl}/api/auth/migration-page?email=$email';
      final uri = Uri.parse(urlString);
      
      debugPrint('尝试打开URL: $urlString');
      
      // 使用更简单的方式打开URL
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).then((success) {
        if (!success) {
          debugPrint('无法打开链接: $urlString');
        }
      });
    } catch (e) {
      debugPrint('打开迁移页面异常: $e');
    }
  }
}