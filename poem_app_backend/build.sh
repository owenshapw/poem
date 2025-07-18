#!/usr/bin/env bash
# Render 构建脚本

echo "🚀 开始构建 PoemVerse 后端服务..."

# 创建必要的目录
mkdir -p uploads

# 设置环境变量
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# 安装依赖
echo "📦 安装 Python 依赖..."
pip install -r requirements.txt

# 清理缓存
echo "🧹 清理缓存..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

echo "✅ 构建完成!" 