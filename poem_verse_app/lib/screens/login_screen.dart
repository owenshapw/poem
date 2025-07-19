import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLogin = true; // 控制是登录还是注册模式
  bool _isResetPassword = false; // 控制是否显示重置密码界面
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 处理登录
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        // 登录成功，导航到我的文章页面
        Navigator.of(context).pushReplacementNamed('/my-articles');
      } else {
        setState(() {
          _errorMessage = result['error'] ?? '登录失败，请检查邮箱和密码';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 处理注册
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final username = _emailController.text.split('@')[0]; // 使用邮箱前缀作为用户名
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        username,
      );

      if (!mounted) return;

      if (success) {
        // 注册成功，显示提示并切换到登录界面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录')),
        );
        setState(() {
          _isLogin = true;
          _tabController.animateTo(0); // 切换到登录标签
        });
      } else {
        setState(() {
          _errorMessage = '注册失败，请稍后再试';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 处理密码重置
  Future<void> _handleResetPassword() async {
    if (_resetEmailController.text.isEmpty) {
      setState(() {
        _errorMessage = '请输入邮箱';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgotPassword(_resetEmailController.text.trim());

      if (!mounted) return;

      if (success) {
        // 发送重置邮件成功，显示提示并返回登录界面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重置密码邮件已发送，请查收')),
        );
        setState(() {
          _isResetPassword = false;
        });
      } else {
        setState(() {
          _errorMessage = '发送重置邮件失败，请稍后再试';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 和标题
                const Text(
                  '诗篇',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '记录你的诗意生活',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                // 根据状态显示不同的表单
                if (_isResetPassword)
                  _buildResetPasswordForm()
                else
                  _buildAuthForm(),
                
                // 错误信息
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // 底部链接
                if (!_isResetPassword)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isResetPassword = true;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('忘记密码？'),
                  ),
                
                if (_isResetPassword)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isResetPassword = false;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('返回登录'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建登录/注册表单
  Widget _buildAuthForm() {
    return Column(
      children: [
        // 登录/注册标签
        TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(text: '登录'),
            Tab(text: '注册'),
          ],
          onTap: (index) {
            setState(() {
              _isLogin = index == 0;
              _errorMessage = null;
            });
          },
        ),
        const SizedBox(height: 20),
        
        // 表单
        Form(
          key: _formKey,
          child: Column(
            children: [
              // 邮箱输入框 - 使用更简单的样式减少约束冲突
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.email),
                    border: InputBorder.none, // 移除边框减少约束
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入邮箱';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 密码输入框 - 使用更简单的样式减少约束冲突
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock),
                    border: InputBorder.none, // 移除边框减少约束
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (!_isLogin && value.length < 6) {
                      return '密码长度至少6位';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // 登录/注册按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isLogin ? _handleLogin : _handleSignUp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isLogin ? '登录' : '注册'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建重置密码表单
  Widget _buildResetPasswordForm() {
    return Column(
      children: [
        const Text(
          '重置密码',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '请输入您的邮箱，我们将发送重置密码链接',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // 邮箱输入框 - 使用更简单的样式减少约束冲突
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _resetEmailController,
            decoration: const InputDecoration(
              labelText: '邮箱',
              prefixIcon: Icon(Icons.email),
              border: InputBorder.none, // 移除边框减少约束
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 24),
        
        // 发送重置邮件按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('发送重置邮件'),
          ),
        ),
      ],
    );
  }
}