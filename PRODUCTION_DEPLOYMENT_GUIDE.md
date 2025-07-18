# PoemVerse 生产环境部署指南

## 后端服务

✅ **已部署到**: https://poemverse.onrender.com

### 后端API端点
- 健康检查: `GET /health`
- 主页文章: `GET /api/articles/home`
- 用户认证: `POST /api/auth/login`, `POST /api/auth/register`
- 文章管理: `GET /api/articles`, `POST /api/articles`, `DELETE /api/articles/:id`
- 图片生成: `POST /api/generate`, `POST /api/generate/preview`

## 前端配置

### 1. 环境变量配置

在 `poem_verse_app/` 目录下创建 `.env` 文件：

```bash
# 开发环境（本地调试）
BACKEND_URL=http://localhost:5001

# 生产环境（部署时使用）
BACKEND_URL=https://poemverse.onrender.com
```

### 2. 应用配置

应用已配置为：
- **当前状态**: 强制使用生产环境 `https://poemverse.onrender.com`
- **调试模式**: 如需本地调试，请修改 `lib/config/app_config.dart`

### 3. 切换开发/生产环境

#### 使用生产环境（当前配置）
```dart
// lib/config/app_config.dart
static String get backendBaseUrl {
  // 强制使用生产环境 - 已部署到Render
  return 'https://poemverse.onrender.com';
}
```

#### 切换回本地开发模式
```dart
// lib/config/app_config.dart
static String get backendBaseUrl {
  // 根据运行环境返回不同的URL
  if (kDebugMode) {
    // 调试模式 - 使用本地开发服务器
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://192.168.14.18:8080';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    } else {
      return 'http://localhost:8080';
    }
  } else {
    // 生产模式 - 使用部署在Render上的服务
    return 'https://poemverse.onrender.com';
  }
}
```

### 4. 构建生产版本

```bash
# 进入Flutter应用目录
cd poem_verse_app

# 构建生产版本
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

## 安全措施

✅ **已完成**:
- `.env` 文件已添加到 `.gitignore`
- `env_example.txt` 中移除了敏感信息
- 使用占位符替代真实API密钥

## 测试生产环境

### 1. 健康检查
```bash
curl https://poemverse.onrender.com/health
```

### 2. 主页文章API
```bash
curl https://poemverse.onrender.com/api/articles/home
```

### 3. Flutter应用测试
1. 构建生产版本: `flutter build apk --release`
2. 安装到设备上测试
3. 确认能正常连接生产API

## 故障排除

### 常见问题

1. **连接超时**
   - 检查网络连接
   - 确认Render服务状态

2. **API返回错误**
   - 检查请求格式
   - 查看后端日志

3. **图片加载失败**
   - 确认图片URL格式正确
   - 检查CORS配置

4. **应用仍连接本地服务器**
   - 确认 `AppConfig.backendBaseUrl` 返回生产URL
   - 重新构建应用

### 调试模式

如需本地调试，确保：
1. 后端服务运行在 `localhost:5001`
2. 修改 `AppConfig.backendBaseUrl` 为本地配置
3. 重新构建应用

## 部署状态

- ✅ 后端: 已部署到 Render
- ✅ 前端配置: 已更新为生产环境
- ✅ 安全配置: 已完成
- ⏳ 前端部署: 待完成（可选）

## 快速切换指南

### 切换到生产环境
1. 确保 `AppConfig.backendBaseUrl` 返回 `https://poemverse.onrender.com`
2. 重新构建应用: `flutter build apk --release`

### 切换到本地开发
1. 修改 `AppConfig.backendBaseUrl` 为本地配置
2. 启动本地后端服务
3. 重新构建应用: `flutter build apk --debug` 