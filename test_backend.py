#!/usr/bin/env python3
"""
后端服务器测试脚本
用于检查后端服务器是否正常工作
"""

import requests
import sys

def test_backend(base_url):
    """测试后端服务器是否正常工作"""
    print(f"测试后端服务器: {base_url}")
    
    # 测试根路径
    try:
        response = requests.get(f"{base_url}")
        print(f"根路径: {response.status_code}")
        if response.status_code == 200:
            print(f"响应: {response.json()}")
    except Exception as e:
        print(f"根路径请求失败: {e}")
    
    # 测试迁移页面路径
    try:
        response = requests.get(f"{base_url}/api/auth/migration-page?email=test@example.com")
        print(f"迁移页面: {response.status_code}")
        if response.status_code == 200:
            print("迁移页面存在")
            print(f"响应长度: {len(response.text)} 字节")
            print(f"响应前100个字符: {response.text[:100]}...")
        else:
            print(f"响应: {response.text}")
    except Exception as e:
        print(f"迁移页面请求失败: {e}")
    
    # 测试健康检查路径
    try:
        response = requests.get(f"{base_url}/health")
        print(f"健康检查: {response.status_code}")
        if response.status_code == 200:
            print(f"响应: {response.json()}")
    except Exception as e:
        print(f"健康检查请求失败: {e}")

if __name__ == "__main__":
    base_url = "https://poemverse.onrender.com"
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    
    test_backend(base_url)