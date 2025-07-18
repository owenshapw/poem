import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  Future<void> _testRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _emailController.text,
      _passwordController.text,
      _usernameController.text,
    );
    
    if (success) {
      _showMessage('注册成功！请检查邮箱进行验证。');
    } else {
      _showMessage('注册失败');
    }
  }

  Future<void> _testLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (result['success'] == true) {
      _showMessage('登录成功！');
    } else {
      _showMessage('登录失败: ${result['error']}');
    }
  }

  Future<void> _testLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    _showMessage('已登出');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Auth 测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testRegister,
              child: const Text('测试注册'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testLogin,
              child: const Text('测试登录'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testLogout,
              child: const Text('测试登出'),
            ),
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('认证状态: ${authProvider.isAuthenticated ? "已登录" : "未登录"}'),
                    if (authProvider.user != null) ...[
                      Text('用户ID: ${authProvider.userId}'),
                      Text('邮箱: ${authProvider.user!['email']}'),
                      Text('用户名: ${authProvider.user!['username']}'),
                      Text('邮箱已验证: ${authProvider.user!['email_confirmed']}'),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_message),
              ),
          ],
        ),
      ),
    );
  }
}