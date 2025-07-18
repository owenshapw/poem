# PoemVerse 安全指南

## 🔒 敏感信息管理

### 重要原则
- **永远不要**将 `.env`、`secret.yaml`、API Token 等敏感文件提交到 Git
- 使用环境变量或 secrets manager 来存储敏感信息
- 定期轮换 API 密钥和密码

### 环境变量配置

#### 后端配置
1. 复制 `poem_app_backend/env_example.txt` 为 `poem_app_backend/.env`
2. 填入实际的配置值：

```bash
# Flask配置
SECRET_KEY=your-actual-secret-key

# Supabase配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-actual-supabase-key

# 邮件配置
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# AI图片生成API密钥
STABILITY_API_KEY=your-stability-ai-api-key
HF_API_KEY=your-hugging-face-api-key

# 应用配置
FLASK_ENV=development
FLASK_DEBUG=True
```

#### 前端配置
1. 复制 `poem_verse_app/env_example.txt` 为 `poem_verse_app/.env`
2. 填入实际的配置值：

```bash
# 后端API地址
BACKEND_URL=http://localhost:5001
```

### 获取API密钥

#### Stability AI API
1. 访问 [Stability AI](https://platform.stability.ai/)
2. 注册账户并获取API密钥
3. 将密钥添加到 `.env` 文件中的 `STABILITY_API_KEY`

#### Hugging Face API
1. 访问 [Hugging Face](https://huggingface.co/)
2. 注册账户并获取API密钥
3. 将密钥添加到 `.env` 文件中的 `HF_API_KEY`

#### Supabase
1. 访问 [Supabase](https://supabase.com/)
2. 创建项目并获取URL和API密钥
3. 将信息添加到 `.env` 文件中

### 部署安全

#### 生产环境
- 使用强密码和长密钥
- 启用HTTPS
- 配置防火墙
- 定期备份数据
- 监控日志

#### 环境变量管理
- 使用云平台的环境变量功能
- 使用 secrets manager 服务
- 避免在代码中硬编码敏感信息

### 安全检查清单

- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] 所有API密钥都通过环境变量配置
- [ ] 生产环境使用强密钥
- [ ] 定期轮换密钥
- [ ] 启用日志监控
- [ ] 配置错误处理

### 常见错误

❌ **错误做法**
```python
# 硬编码API密钥
api_key = "sk-1234567890abcdef"
```

✅ **正确做法**
```python
# 使用环境变量
api_key = os.getenv('API_KEY')
```

### 紧急情况

如果发现敏感信息泄露：
1. 立即轮换所有相关密钥
2. 检查Git历史记录
3. 通知相关团队
4. 更新安全策略

---

**记住：安全是每个人的责任！** 