#!/usr/bin/env python3
"""
检查 Cloudflare Images 环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载 .env 文件（如果存在）
load_dotenv()

print("=== Cloudflare Images 环境变量检查 ===")
print()

# 检查必需的环境变量
required_vars = [
    'CLOUDFLARE_ACCOUNT_ID',
    'CLOUDFLARE_API_TOKEN'
]

for var in required_vars:
    value = os.getenv(var)
    if value:
        # 对于敏感信息，只显示前几个字符
        if 'TOKEN' in var:
            display_value = value[:8] + '***' if len(value) > 8 else '***'
        else:
            display_value = value
        print(f"✅ {var}: {display_value}")
    else:
        print(f"❌ {var}: 未设置")

print()

# 显示完整的配置信息
print("=== 当前 Cloudflare 配置 ===")
print(f"Account ID: {os.getenv('CLOUDFLARE_ACCOUNT_ID', '未设置')}")
print(f"API Token: {os.getenv('CLOUDFLARE_API_TOKEN', '未设置')[:8] + '***' if os.getenv('CLOUDFLARE_API_TOKEN') else '未设置'}")

print()

# 测试 Cloudflare 客户端初始化
try:
    from utils.cloudflare_client import cloudflare_client
    print("=== Cloudflare 客户端测试 ===")
    if cloudflare_client.is_available():
        print("✅ Cloudflare 客户端初始化成功")
        print(f"   Account ID: {cloudflare_client.account_id}")
    else:
        print("❌ Cloudflare 客户端初始化失败")
except Exception as e:
    print(f"❌ Cloudflare 客户端测试失败: {e}")

print()

# 提供配置说明
print("=== 配置说明 ===")
print("1. 登录 Cloudflare 控制台")
print("2. 进入 'Images' 页面")
print("3. 复制 Account ID（在页面右上角）")
print("4. 创建 API Token：")
print("   - 进入 'My Profile' > 'API Tokens'")
print("   - 点击 'Create Token'")
print("   - 选择 'Custom token'")
print("   - 权限设置：")
print("     * Account > Cloudflare Images > Edit")
print("     * Zone > Zone > Read")
print("5. 将 Account ID 和 API Token 添加到 .env 文件中") 