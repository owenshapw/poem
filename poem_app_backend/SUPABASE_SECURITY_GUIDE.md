# Supabase安全策略实施指南

## 概述
本指南详细说明了如何为诗篇应用实施Supabase安全策略，包括认证系统和行级安全(RLS)策略。

## 1. 认证系统升级

### 1.1 从自定义JWT迁移到Supabase Auth
- ✅ 使用Supabase内置认证服务
- ✅ 自动处理密码加密和安全存储
- ✅ 内置邮箱验证功能
- ✅ 安全的token管理和刷新机制

### 1.2 新的认证流程
```python
# 注册
result = supabase_auth_client.sign_up(email, password, username)

# 登录
result = supabase_auth_client.sign_in(email, password)

# 验证token
result = supabase_auth_client.verify_token(access_token)
```

## 2. 数据库安全策略 (RLS)

### 2.1 启用行级安全
```sql
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
```

### 2.2 文章表安全策略
- **查看**: 所有人可查看已发布文章
- **创建**: 仅认证用户可创建
- **更新**: 仅作者可更新自己的文章
- **删除**: 仅作者可删除自己的文章

### 2.3 评论表安全策略
- **查看**: 所有人可查看评论
- **创建**: 仅认证用户可创建
- **更新**: 仅评论者可更新自己的评论
- **删除**: 仅评论者可删除自己的评论

## 3. 安全最佳实践

### 3.1 Token管理
- 使用短期访问令牌 (1小时)
- 实施刷新令牌机制
- 客户端安全存储令牌

### 3.2 API安全
- 所有敏感操作需要认证
- 使用HTTPS传输
- 实施请求频率限制

### 3.3 数据验证
- 服务端验证所有输入
- 防止SQL注入和XSS攻击
- 实施内容过滤

## 4. 部署配置

### 4.1 Supabase项目设置
1. 启用邮箱验证
2. 配置邮件模板
3. 设置密码策略
4. 配置OAuth提供商(可选)

### 4.2 环境变量
```bash
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
```

### 4.3 RLS策略部署
执行 `database/rls_policies.sql` 中的SQL语句

## 5. 迁移步骤

### 5.1 后端迁移
1. ✅ 创建新的认证客户端
2. ✅ 更新认证路由
3. ✅ 实施认证中间件
4. ✅ 更新所有受保护的路由

### 5.2 数据库迁移
1. 执行RLS策略SQL
2. 迁移现有用户数据(如需要)
3. 更新用户ID格式为UUID

### 5.3 前端迁移
1. 更新认证API调用
2. 实施token刷新逻辑
3. 更新用户状态管理

## 6. 测试验证

### 6.1 认证测试
- [ ] 用户注册流程
- [ ] 邮箱验证
- [ ] 用户登录
- [ ] Token刷新
- [ ] 密码重置

### 6.2 权限测试
- [ ] 未认证用户访问限制
- [ ] 用户只能操作自己的数据
- [ ] RLS策略生效验证

### 6.3 安全测试
- [ ] Token过期处理
- [ ] 无效token拒绝
- [ ] 跨用户数据访问阻止

## 7. 监控和维护

### 7.1 日志监控
- 认证失败日志
- 权限拒绝日志
- 异常访问模式

### 7.2 性能监控
- 认证响应时间
- 数据库查询性能
- RLS策略影响

## 8. 故障排除

### 8.1 常见问题
- Token验证失败
- RLS策略阻止访问
- 邮箱验证问题

### 8.2 调试工具
- Supabase Dashboard
- 数据库日志
- 应用程序日志

## 结论
通过实施这些安全策略，诗篇应用将获得：
- 企业级认证安全
- 数据访问控制
- 符合最佳实践的架构
- 可扩展的安全框架