# 📘 PoemVerse 项目开发总指南（产品 + 技术）

本文件包含两个部分：

1. 产品需求文档（PRD）
2. Cursor 技术开发指令

---

## 📄 一、产品需求文档（PRD）


# 📄 产品需求文档（PRD）：诗篇 App

## 一、产品概述

**产品名称**：诗篇  
**产品定位**：一款融合诗词创作与出版美学的沉浸式内容平台，让用户发布、阅读、分享如同艺术画册般精美的诗词文章。  

---

## 二、目标用户

- 喜欢写诗、散文、短文的创作者
- 喜欢欣赏美学排版、文艺内容的阅读者
- 渴望沉浸式体验的文化内容爱好者

---

## 三、核心功能模块

### 1. 用户系统

| 功能 | 描述 |
|------|------|
| 邮箱注册/登录 | 用户通过邮箱注册账户，登录后可访问完整功能 |
| 忘记密码 | 提供找回密码功能（通过邮箱验证码或链接） |

---

### 2. 内容管理

| 功能 | 描述 |
|------|------|
| 上传文章 | 输入标题、正文、关键词标签、作者名等 |
| 查看文章 | 可查看自己上传的文章 |
| 删除文章 | 用户可以删除自己上传的内容 |

---

### 3. AI 排版与配图（自动美化）

| 功能 | 描述 |
|------|------|
| 自动排版 | AI自动将用户文章生成出版物风格页面（如竖排对齐、古典字体、留白、页码等） |
| 智能配图 | 根据文章情绪与关键词智能匹配意境图画，生成图文页面 |
| 本地预览 | 提供预览图，可作为图像下载或转发 |

---

### 4. 内容展示与沉浸式阅读

| 功能 | 描述 |
|------|------|
| 首页内容流 | 所有用户可浏览的图文内容，以色块区块分组显示文章标题+前几句正文 |
| 滑动翻阅 | 以诗集形式呈现，用户可上下滑动切换文章页面 |
| 沉浸模式 | 阅读时隐藏导航栏，点击屏幕召唤导航 |
| 标签导航 | 每篇文章可通过关键词（如“爱”“故乡”“张三”）跳转到相关内容 |
| 作者视图 | 浏览某个作者的全部文章，可按时间线或标题浏览 |

---

### 5. 互动与社区

| 功能 | 描述 |
|------|------|
| 点评 | 登录用户可以对内容发表评论或点赞 |
| 点评不喧宾夺主 | 评论区默认收起，不影响翻阅沉浸体验，需点击图标展开 |

---

### 6. 内容下载与分享

| 功能 | 描述 |
|------|------|
| 下载 | 可将每篇诗词文章下载为图文排版图片（JPEG/PNG） |
| 转发 | 支持分享到社交平台（微信、朋友圈、微博、Instagram 等） |

---

## 四、页面结构与交互逻辑

```
启动页 → 首页（内容流）→ 文章详情页（沉浸阅读） 
                          ↘ 标签/作者浏览页 → 某文章
                          ↘ 登录页 / 注册页
                          ↘ 我的文章页（上传/管理）
```

---

## 五、技术架构建议

| 模块 | 技术建议 |
|------|----------|
| 前端 | Flutter（跨平台）、支持沉浸式滚动与动画 |
| 后端 | Flask / Node.js + MongoDB / PostgreSQL |
| AI配图 | OpenAI / Stability API + 自建关键词图像匹配逻辑 |
| 图片生成 | HTML/CSS 排版 → Headless Chrome 截图 或 Canvas 渲染为图片 |
| 存储 | AWS S3 / 阿里云 OSS 储存用户图文、AI生成图 |
| 用户系统 | Firebase Auth 或自建邮箱认证逻辑（含邮件服务） |

---

## 六、未来可拓展功能（可选）

- 语音朗读诗词（TTS）
- AI辅助创作建议（句式优化、对仗检测等）
- 付费订阅或赞赏系统
- 每日诗选推送


---

## 🛠️ 二、Cursor 技术开发指令


# 📘 Cursor 开发指令文档：「诗篇」APP 后端开发

## 一、项目概述

**项目名称**：诗篇（PoemVerse）

**目标**：开发一个后端服务，支持诗词文章上传、AI图文排版生成、沉浸式阅读、用户评论、内容下载分享等功能。

---

## 二、技术选型

- **后端框架**：Flask
- **数据库**：Supabase
- **邮件服务**：Gmail SMTP
- **部署平台**：Render
- **图文生成**：HTML 模板转图片 或 PIL 图像合成

---

## 三、项目目录结构建议

```
/poem_app_backend
├── app.py                  # Flask 主入口
├── routes/
│   ├── auth.py             # 注册、登录、找回密码
│   ├── articles.py         # 上传、删除、获取文章
│   ├── comments.py         # 评论模块
│   ├── generate.py         # AI排版与配图
├── models/
│   ├── supabase_client.py  # 封装 Supabase 查询与写入
├── utils/
│   ├── mail.py             # Gmail 邮件发送
│   ├── image_generator.py  # 图文合成逻辑
├── templates/
│   ├── article_template.html  # 用于排版的HTML模板
├── requirements.txt
├── config.py               # 环境变量加载
├── Procfile                # Render 启动文件
```

---

## 四、环境变量清单（.env）

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_KEY=your_supabase_key
EMAIL_USERNAME=your@gmail.com
EMAIL_PASSWORD=your_app_password
```

---

## 五、接口说明

### 1. 注册用户

```
POST /api/register
Body: {
  "email": "user@example.com",
  "password": "123456"
}
```

### 2. 用户登录

```
POST /api/login
Body: {
  "email": "user@example.com",
  "password": "123456"
}
```

### 3. 上传文章

```
POST /api/articles
Body: {
  "title": "春日",
  "content": "山光悦鸟性，潭影空人心",
  "tags": ["春天", "自然"],
  "author": "张三"
}
返回：文章ID + 图文图片 URL
```

### 4. 获取文章列表（首页流）

```
GET /api/articles
返回：所有用户的文章摘要信息（标题、作者、标签、缩略内容）
```

### 5. 获取单篇文章

```
GET /api/articles/<id>
返回：详细内容 + 图文排版图片 URL + 评论列表
```

### 6. 删除文章

```
DELETE /api/articles/<id>
需登录授权，仅删除本人文章
```

### 7. AI图文排版与生成

```
POST /api/generate
Body: {
  "article_id": "<uuid>"
}
功能：根据文章内容生成排版图，存至 Supabase 存储并返回 URL
```

### 8. 评论文章

```
POST /api/comments
Body: {
  "article_id": "<uuid>",
  "content": "好美的一句"
}
```

---

## 六、Supabase 数据表结构

### 表：users

| 字段 | 类型 | 描述 |
|------|------|------|
| id | uuid | 主键 |
| email | text | 邮箱 |
| password_hash | text | 加密密码 |
| created_at | timestamp | 创建时间 |

### 表：articles

| 字段 | 类型 | 描述 |
|------|------|------|
| id | uuid | 主键 |
| user_id | uuid | 作者 |
| title | text | 标题 |
| content | text | 正文 |
| tags | text[] | 标签关键词 |
| author | text | 作者名 |
| image_url | text | AI生成图文链接 |
| created_at | timestamp | 上传时间 |

### 表：comments

| 字段 | 类型 | 描述 |
|------|------|------|
| id | uuid | 主键 |
| article_id | uuid | 文章ID |
| user_id | uuid | 评论者 |
| content | text | 评论正文 |
| created_at | timestamp | 评论时间 |

---

## 七、开发提示

- 使用 bcrypt 对密码加密存储
- 使用 Flask Blueprint 分模块开发
- 用 `smtplib` 或 `flask-mail` 发送 Gmail 邮件
- 图文排版建议：
  - 使用 Jinja2 渲染 HTML 模板
  - 用 `html2image`, `WeasyPrint`, 或 `selenium + headless chrome` 生成高质量图像

---

## 八、第一步：初始开发指令（Cursor Prompt）

> 请用 Flask 搭建“诗篇”项目后端框架，使用 Supabase 作为数据库，Gmail SMTP 用于发送注册/找回邮件。实现以下路由：
>
> - `/api/register`：注册用户
> - `/api/login`：用户登录
> - `/api/articles`：上传并保存文章
> - `/api/generate`：根据文章生成图文排版图像（可模拟图片生成逻辑）
>
> 请采用模块化结构组织代码，使用 Blueprint、环境变量配置，并提供 requirements.txt。
