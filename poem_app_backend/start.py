#!/usr/bin/env python3
"""
诗篇后端快速启动脚本
"""

import os
import sys
import subprocess

def check_python_version():
    """检查Python版本"""
    if sys.version_info < (3, 8):
        print("❌ 需要Python 3.8或更高版本")
        print(f"当前版本: {sys.version}")
        return False
    print(f"✅ Python版本: {sys.version.split()[0]}")
    return True

def check_dependencies():
    """检查依赖是否安装"""
    print("🔍 检查依赖...")
    
    try:
        import flask
        import flask_cors
        import dotenv
        import supabase
        import bcrypt
        import jwt
        from PIL import Image
        print("✅ 所有依赖已安装")
        return True
    except ImportError as e:
        print(f"❌ 缺少依赖: {e}")
        print("请运行: pip install -r requirements.txt")
        return False

def check_env_file():
    """检查环境变量文件"""
    if not os.path.exists('.env'):
        print("⚠️  未找到 .env 文件")
        print("请复制 env_example.txt 为 .env 并配置环境变量")
        return False
    print("✅ 找到 .env 文件")
    return True

def check_supabase_config():
    """检查Supabase配置"""
    try:
        from config import Config
        config = Config()
        
        if not config.SUPABASE_URL or config.SUPABASE_URL == 'https://xxxx.supabase.co':
            print("⚠️  Supabase URL 未配置")
            return False
        if not config.SUPABASE_KEY or config.SUPABASE_KEY == 'your_supabase_key':
            print("⚠️  Supabase Key 未配置")
            return False
            
        print("✅ Supabase配置已设置")
        return True
    except Exception as e:
        print(f"❌ 配置检查失败: {e}")
        return False

def start_app():
    """启动应用"""
    print("\n🚀 启动诗篇后端服务...")
    
    try:
        # 设置环境变量
        os.environ['FLASK_ENV'] = 'development'
        os.environ['FLASK_DEBUG'] = 'True'
        
        # 启动Flask应用
        from app import create_app
        app = create_app()
        
        print("✅ 应用启动成功!")
        print("📱 API服务地址: http://localhost:5001")
        print("🔍 健康检查: http://localhost:5001/health")
        print("📚 API文档: 查看 README.md")
        print("\n按 Ctrl+C 停止服务")
        
        app.run(debug=True, host='0.0.0.0', port=5001)
        
    except Exception as e:
        print(f"❌ 启动失败: {e}")
        return False

def main():
    """主函数"""
    print("🎯 诗篇后端启动检查\n")
    
    checks = [
        check_python_version,
        check_dependencies,
        check_env_file,
        check_supabase_config
    ]
    
    all_passed = True
    for check in checks:
        if not check():
            all_passed = False
            print()
    
    if not all_passed:
        print("❌ 启动检查失败，请解决上述问题后重试")
        print("\n📝 常见问题解决:")
        print("1. 安装依赖: pip install -r requirements.txt")
        print("2. 配置环境变量: 复制 env_example.txt 为 .env")
        print("3. 设置Supabase: 在 .env 中配置数据库连接")
        return 1
    
    print("\n✅ 所有检查通过!")
    
    # 询问是否启动
    try:
        response = input("是否现在启动服务? (y/n): ").lower().strip()
        if response in ['y', 'yes', '是']:
            start_app()
        else:
            print("👋 再见!")
    except KeyboardInterrupt:
        print("\n👋 再见!")
    
    return 0

if __name__ == '__main__':
    sys.exit(main()) 