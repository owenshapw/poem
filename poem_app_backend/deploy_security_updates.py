#!/usr/bin/env python3
"""
安全更新部署脚本
用于部署Supabase认证和RLS安全策略
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv

def load_environment():
    """加载环境变量"""
    load_dotenv()
    
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ 错误: 请设置 SUPABASE_URL 和 SUPABASE_KEY 环境变量")
        sys.exit(1)
    
    return supabase_url, supabase_key

def check_supabase_connection(supabase_url, supabase_key):
    """检查Supabase连接"""
    try:
        supabase = create_client(supabase_url, supabase_key)
        # 尝试一个简单的查询来测试连接
        result = supabase.table('articles').select('id').limit(1).execute()
        print("✅ Supabase连接成功")
        return supabase
    except Exception as e:
        print(f"❌ Supabase连接失败: {e}")
        sys.exit(1)

def execute_rls_policies(supabase):
    """执行RLS策略"""
    print("\n📋 开始执行RLS策略...")
    
    # 读取RLS策略文件
    rls_file_path = os.path.join(os.path.dirname(__file__), 'database', 'rls_policies.sql')
    
    if not os.path.exists(rls_file_path):
        print(f"❌ 错误: 找不到RLS策略文件: {rls_file_path}")
        return False
    
    try:
        with open(rls_file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("⚠️  注意: RLS策略需要在Supabase Dashboard的SQL编辑器中手动执行")
        print("📄 RLS策略文件位置:", rls_file_path)
        print("\n请按照以下步骤操作:")
        print("1. 登录Supabase Dashboard")
        print("2. 进入SQL编辑器")
        print("3. 复制并执行database/rls_policies.sql中的内容")
        print("4. 验证策略是否正确应用")
        
        return True
        
    except Exception as e:
        print(f"❌ 读取RLS策略文件失败: {e}")
        return False

def verify_tables_exist(supabase):
    """验证必要的表是否存在"""
    print("\n🔍 验证数据库表...")
    
    required_tables = ['articles', 'comments']
    
    for table in required_tables:
        try:
            result = supabase.table(table).select('*').limit(1).execute()
            print(f"✅ 表 '{table}' 存在")
        except Exception as e:
            print(f"❌ 表 '{table}' 不存在或无法访问: {e}")
            return False
    
    return True

def check_auth_configuration():
    """检查认证配置"""
    print("\n🔐 检查认证配置...")
    
    # 检查必要的文件是否存在
    required_files = [
        'models/supabase_auth_client.py',
        'utils/auth_middleware.py',
        'routes/auth.py'
    ]
    
    for file_path in required_files:
        full_path = os.path.join(os.path.dirname(__file__), file_path)
        if os.path.exists(full_path):
            print(f"✅ {file_path} 存在")
        else:
            print(f"❌ {file_path} 不存在")
            return False
    
    return True

def display_next_steps():
    """显示后续步骤"""
    print("\n🚀 部署后续步骤:")
    print("1. 在Supabase Dashboard中执行RLS策略")
    print("2. 配置邮箱验证设置（如需要）")
    print("3. 重启应用服务")
    print("4. 运行测试验证功能")
    print("5. 监控应用日志")
    
    print("\n📋 测试检查清单:")
    print("□ 用户注册流程")
    print("□ 用户登录/登出")
    print("□ Token刷新机制")
    print("□ 权限控制验证")
    print("□ RLS策略生效")

def main():
    """主函数"""
    print("🔒 诗篇应用安全更新部署脚本")
    print("=" * 50)
    
    # 加载环境变量
    supabase_url, supabase_key = load_environment()
    
    # 检查Supabase连接
    supabase = check_supabase_connection(supabase_url, supabase_key)
    
    # 验证表存在
    if not verify_tables_exist(supabase):
        print("❌ 数据库表验证失败")
        sys.exit(1)
    
    # 检查认证配置文件
    if not check_auth_configuration():
        print("❌ 认证配置文件检查失败")
        sys.exit(1)
    
    # 执行RLS策略
    if not execute_rls_policies(supabase):
        print("❌ RLS策略部署失败")
        sys.exit(1)
    
    # 显示后续步骤
    display_next_steps()
    
    print("\n✅ 安全更新部署准备完成!")
    print("请按照上述步骤完成剩余的配置工作。")

if __name__ == "__main__":
    main()