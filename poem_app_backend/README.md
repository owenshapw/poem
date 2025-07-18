# 诗篇 (PoemVerse) 后端API

一个专为诗词创作与分享设计的后端服务，支持AI图文排版生成、用户认证、内容管理等功能。

## 功能特性

- 🔐 用户认证系统（注册、登录、密码重置）
- 📝 文章管理（上传、编辑、删除、搜索）
- 🎨 AI图文排版生成
- 💬 评论系统
- 📧 邮件通知服务
- 🔍 内容搜索和标签导航

## 技术栈

- **后端框架**: Flask
- **数据库**: Supabase (PostgreSQL)
- **图片处理**: Pillow (PIL)
- **认证**: JWT + bcrypt
- **邮件服务**: Gmail SMTP
- **部署**: Render

## 快速开始

### 1. 环境准备

确保已安装Python 3.8+和pip。

### 2. 克隆项目

```bash
git clone <repository-url>
cd poem_app_backend
```

### 3. 安装依赖

```bash
pip install -r requirements.txt
```

### 4. 环境配置

创建 `.env` 文件并配置以下环境变量：

```env
# Flask配置
SECRET_KEY=your-secret-key-here

# Supabase配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key

# 邮件配置
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# 应用配置
FLASK_ENV=development
FLASK_DEBUG=True
```

### 5. 数据库设置

在Supabase中创建以下数据表：

#### users表
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### articles表
```sql
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    author TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### comments表
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 6. 运行应用

```bash
python app.py
```

应用将在 `http://localhost:5001` 启动。

## API接口文档

### 认证接口

#### 用户注册
```
POST /api/register
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "123456"
}
```

#### 用户登录
```
POST /api/login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "123456"
}
```

#### 忘记密码
```
POST /api/forgot-password
Content-Type: application/json

{
    "email": "user@example.com"
}
```

### 文章接口

#### 上传文章
```
POST /api/articles
Authorization: Bearer <token>
Content-Type: application/json

{
    "title": "春日",
    "content": "山光悦鸟性，潭影空人心",
    "tags": ["春天", "自然"],
    "author": "张三"
}
```

#### 获取文章列表
```
GET /api/articles
```

#### 获取单篇文章
```
GET /api/articles/<article_id>
```

#### 删除文章
```
DELETE /api/articles/<article_id>
Authorization: Bearer <token>
```

#### 搜索文章
```
GET /api/articles/search?tag=春天&author=张三
```

### 评论接口

#### 发表评论
```
POST /api/comments
Authorization: Bearer <token>
Content-Type: application/json

{
    "article_id": "<uuid>",
    "content": "好美的一句"
}
```

#### 获取文章评论
```
GET /api/articles/<article_id>/comments
```

### 图片生成接口

#### 生成文章图片
```
POST /api/generate
Authorization: Bearer <token>
Content-Type: application/json

{
    "article_id": "<uuid>"
}
```

#### 批量生成图片
```
POST /api/generate/batch
Authorization: Bearer <token>
```

#### 生成预览图片
```
POST /api/generate/preview
Authorization: Bearer <token>
Content-Type: application/json

{
    "title": "春日",
    "content": "山光悦鸟性，潭影空人心",
    "tags": ["春天", "自然"],
    "author": "张三"
}
```

## 部署到Render

1. 将代码推送到GitHub
2. 在Render中创建新的Web Service
3. 连接GitHub仓库
4. 配置环境变量
5. 设置构建命令：`pip install -r requirements.txt`
6. 设置启动命令：`gunicorn app:create_app()`

## 项目结构

```
poem_app_backend/
├── app.py                  # Flask主入口
├── config.py              # 配置文件
├── requirements.txt       # 依赖包
├── Procfile              # Render部署配置
├── README.md             # 项目说明
├── routes/               # 路由模块
│   ├── auth.py          # 认证路由
│   ├── articles.py      # 文章路由
│   ├── comments.py      # 评论路由
│   └── generate.py      # 图片生成路由
├── models/              # 数据模型
│   └── supabase_client.py
├── utils/               # 工具模块
│   ├── mail.py         # 邮件工具
│   └── image_generator.py
└── templates/           # HTML模板
    └── article_template.html
```

## 开发说明

### 添加新功能

1. 在 `routes/` 目录下创建新的路由文件
2. 在 `app.py` 中注册新的蓝图
3. 更新 `models/supabase_client.py` 添加数据库操作
4. 测试新功能

### 自定义图片生成

修改 `utils/image_generator.py` 中的 `generate_article_image` 函数来自定义图片样式。

### 扩展邮件功能

在 `utils/mail.py` 中添加新的邮件模板和发送函数。

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交Issue或联系开发团队。 