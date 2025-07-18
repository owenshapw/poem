#!/usr/bin/env python3
"""
自动检测数据库中所有 image_url 并比对 uploads 目录下的实际文件
"""

import os
import sys
from models.supabase_client import supabase_client
from config import Config

def check_images():
    """检查数据库中所有图片URL对应的文件是否存在"""
    
    # 初始化 Supabase 客户端
    from flask import Flask
    app = Flask(__name__)
    app.config.from_object(Config())
    supabase_client.init_app(app)
    
    # 检查 Supabase 客户端是否初始化成功
    if supabase_client.supabase is None:
        print("❌ Supabase 客户端初始化失败")
        return
    
    # 获取 uploads 目录路径
    uploads_dir = os.path.join(os.path.dirname(__file__), 'uploads')
    
    # 获取数据库中所有文章
    try:
        result = supabase_client.supabase.table('articles').select('id, title, image_url').execute()
        articles = result.data
    except Exception as e:
        print(f"获取数据库文章失败: {e}")
        return
    
    print(f"数据库中共有 {len(articles)} 篇文章")
    print("=" * 80)
    
    # 统计信息
    total_images = 0
    existing_images = 0
    missing_images = 0
    invalid_urls = 0
    
    # 检查每篇文章的图片
    for article in articles:
        image_url = article.get('image_url')
        title = article.get('title', '无标题')
        article_id = article.get('id')
        
        if not image_url:
            print(f"❌ 文章 '{title}' (ID: {article_id}) - 无图片URL")
            invalid_urls += 1
            continue
        
        total_images += 1
        
        # 处理相对路径
        if image_url.startswith('/uploads/'):
            filename = image_url.replace('/uploads/', '')
        elif image_url.startswith('uploads/'):
            filename = image_url.replace('uploads/', '')
        else:
            filename = image_url
        
        # 检查文件是否存在
        file_path = os.path.join(uploads_dir, filename)
        
        if os.path.exists(file_path):
            file_size = os.path.getsize(file_path)
            print(f"✅ 文章 '{title}' - 图片存在: {filename} ({file_size} bytes)")
            existing_images += 1
        else:
            print(f"❌ 文章 '{title}' - 图片缺失: {filename}")
            missing_images += 1
    
    print("=" * 80)
    print("统计结果:")
    print(f"总图片数: {total_images}")
    print(f"存在图片: {existing_images}")
    print(f"缺失图片: {missing_images}")
    print(f"无效URL: {invalid_urls}")
    
    if missing_images > 0:
        print(f"\n⚠️  有 {missing_images} 个图片文件缺失，建议:")
        print("1. 检查图片生成/上传流程")
        print("2. 重新生成缺失的图片")
        print("3. 或手动上传同名图片到 uploads 目录")
    
    # 列出 uploads 目录下的所有文件
    print("\n" + "=" * 80)
    print("uploads 目录下的所有文件:")
    if os.path.exists(uploads_dir):
        files = os.listdir(uploads_dir)
        for file in sorted(files):
            file_path = os.path.join(uploads_dir, file)
            if os.path.isfile(file_path):
                file_size = os.path.getsize(file_path)
                print(f"📁 {file} ({file_size} bytes)")
    else:
        print("❌ uploads 目录不存在")

if __name__ == '__main__':
    check_images() 