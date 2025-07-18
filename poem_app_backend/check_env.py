#!/usr/bin/env python3
"""
检查环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def check_env_vars():
    """检查环境变量"""
    print("🔍 检查环境变量配置...")
    print("=" * 50)
    
    
    
    print("\nSupabase配置:")
    supabase_vars = {
        'SUPABASE_URL': os.getenv('SUPABASE_URL'),
        'SUPABASE_KEY': os.getenv('SUPABASE_KEY'),
    }
    
    for var, value in supabase_vars.items():
        if value:
            if 'KEY' in var:
                print(f"  ✅ {var}: {'*' * len(value)}")
            else:
                print(f"  ✅ {var}: {value}")
        else:
            print(f"  ❌ {var}: 未设置")
    
    print("\n其他配置:")
    other_vars = {
        'SECRET_KEY': os.getenv('SECRET_KEY'),
        'FLASK_ENV': os.getenv('FLASK_ENV'),
        'FLASK_DEBUG': os.getenv('FLASK_DEBUG'),
    }
    
    for var, value in other_vars.items():
        if value:
            print(f"  ✅ {var}: {value}")
        else:
            print(f"  ❌ {var}: 未设置")
    
    
    
    # 检查是否在Render环境
    if os.getenv('RENDER'):
        print("🌐 当前运行在Render环境")
    else:
        print("💻 当前运行在本地环境")

if __name__ == "__main__":
    check_env_vars() 