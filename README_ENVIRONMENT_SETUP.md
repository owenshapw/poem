# PoemVerse 环境设置指南

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <your-repo-url>
cd poemVerse
```

### 2. 后端环境设置

#### 2.1 创建虚拟环境
```bash
cd poem_app_backend
python3 -m venv .venv
source .venv/bin/activate  # macOS/Linux
# 或
.venv\Scripts\activate  # Windows
```

#### 2.2 安装依赖
```bash
pip install -r requirements.txt
```

#### 2.3 配置环境变量
```bash
# 复制环境变量示例文件
cp env_example.txt .env

# 编辑 .env 文件，填入实际值
nano .env  # 或使用其他编辑器
```

#### 2.4 启动后端服务
```bash
python3 app.py
```

### 3. 前端环境设置

#### 3.1 安装Flutter依赖
```bash
cd poem_verse_app
flutter pub get
```

#### 3.2 配置环境变量
```bash
# 复制环境变量示例文件
cp env_example.txt .env

# 编辑 .env 文件，填入实际值
nano .env  # 或使用其他编辑器
```

#### 3.3 启动Flutter应用
```bash
flutter run
```

## 🔧 环境变量配置

### 后端必需的环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `SECRET_KEY` | Flask密钥 | `your-secret-key-here` |
| `SUPABASE_URL` | Supabase项目URL | `https://your-project.supabase.co` |
| `SUPABASE_KEY` | Supabase匿名密钥 | `your-supabase-anon-key` |
| `EMAIL_USERNAME` | 邮箱用户名 | `your-email@gmail.com` |
| `EMAIL_PASSWORD` | 邮箱应用密码 | `your-app-password` |
| `STABILITY_API_KEY` | Stability AI API密钥 | `your-stability-ai-api-key` |
| `HF_API_KEY` | Hugging Face API密钥 | `your-hugging-face-api-key` |

### 前端必需的环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `BACKEND_URL` | 后端API地址 | `http://localhost:5001` |

## 🔑 获取API密钥

### Stability AI API
1. 访问 [Stability AI Platform](https://platform.stability.ai/)
2. 注册账户
3. 在API Keys页面获取密钥
4. 添加到 `.env` 文件

### Hugging Face API
1. 访问 [Hugging Face](https://huggingface.co/)
2. 注册账户
3. 在Settings > Access Tokens页面获取密钥
4. 添加到 `.env` 文件

### Supabase
1. 访问 [Supabase](https://supabase.com/)
2. 创建新项目
3. 在Settings > API页面获取URL和密钥
4. 添加到 `.env` 文件

## 🧪 测试配置

### 测试环境变量
```bash
# 可选：设置测试专用环境变量
export TEST_EMAIL=your-test-email@gmail.com
export TEST_PASSWORD=your-test-password
export TEST_BASE_URL=http://localhost:5001
```

### 运行测试
```bash
cd poem_app_backend
python3 test_login.py
python3 test_articles.py
# 等等...
```

## 🔒 安全注意事项

1. **永远不要**提交 `.env` 文件到Git
2. 使用强密码和长密钥
3. 定期轮换API密钥
4. 在生产环境中使用环境变量管理服务

## 🐛 常见问题

### 问题1：找不到 .env 文件
**解决方案：** 确保已复制 `env_example.txt` 为 `.env`

### 问题2：API密钥无效
**解决方案：** 检查API密钥是否正确，确保有足够的配额

### 问题3：端口被占用
**解决方案：** 更改端口或停止占用端口的进程

### 问题4：Flutter无法连接后端
**解决方案：** 检查 `BACKEND_URL` 配置和网络连接

## 📞 获取帮助

如果遇到问题：
1. 检查环境变量配置
2. 查看日志输出
3. 参考 `SECURITY_GUIDE.md`
4. 提交Issue到项目仓库 