#!/usr/bin/env python3
"""
迁移状态检查工具
用于监控用户从旧认证系统到Supabase Auth的迁移进度
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv
from datetime import datetime
import argparse

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
        print("✅ Supabase连接成功")
        return supabase
    except Exception as e:
        print(f"❌ Supabase连接失败: {e}")
        sys.exit(1)

def count_legacy_users(supabase):
    """统计旧系统用户数量"""
    try:
        result = supabase.table('users').select('id').execute()
        return len(result.data) if result.data else 0
    except Exception as e:
        print(f"❌ 统计旧系统用户失败: {e}")
        return 0

def count_supabase_users(supabase):
    """统计Supabase Auth用户数量"""
    try:
        # 注意：这需要管理员权限，可能需要在Supabase Dashboard中查看
        print("ℹ️  Supabase Auth用户数量需要在Supabase Dashboard中查看")
        print("   路径: Authentication > Users")
        return None
    except Exception as e:
        print(f"❌ 统计Supabase Auth用户失败: {e}")
        return None

def check_data_consistency(supabase):
    """检查数据一致性"""
    try:
        # 检查文章表中是否有旧格式的用户ID
        articles_result = supabase.table('articles').select('user_id').execute()
        comments_result = supabase.table('comments').select('user_id').execute()
        
        if not articles_result.data or not comments_result.data:
            return True
        
        # 检查是否有非UUID格式的用户ID
        non_uuid_articles = [a for a in articles_result.data if not is_valid_uuid(a.get('user_id', ''))]
        non_uuid_comments = [c for c in comments_result.data if not is_valid_uuid(c.get('user_id', ''))]
        
        if non_uuid_articles:
            print(f"⚠️  发现 {len(non_uuid_articles)} 篇文章使用旧格式用户ID")
        
        if non_uuid_comments:
            print(f"⚠️  发现 {len(non_uuid_comments)} 条评论使用旧格式用户ID")
        
        return len(non_uuid_articles) == 0 and len(non_uuid_comments) == 0
    except Exception as e:
        print(f"❌ 检查数据一致性失败: {e}")
        return False

def is_valid_uuid(value):
    """检查是否为有效的UUID格式"""
    import re
    uuid_pattern = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', re.I)
    return bool(uuid_pattern.match(value))

def generate_report(legacy_count, data_consistent):
    """生成迁移状态报告"""
    print("\n📊 迁移状态报告")
    print("=" * 50)
    print(f"检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"剩余旧系统用户: {legacy_count}")
    
    if legacy_count == 0:
        if data_consistent:
            print("✅ 迁移完成！所有用户已迁移到新系统，数据一致性良好。")
        else:
            print("⚠️  所有用户已迁移，但数据一致性存在问题，需要检查。")
    else:
        completion_rate = "未知"  # 因为我们无法直接获取Supabase Auth用户数量
        print(f"⏳ 迁移进行中 - 完成率: {completion_rate}")
        print(f"   剩余 {legacy_count} 个用户需要迁移")
        
        if not data_consistent:
            print("⚠️  数据一致性存在问题，需要检查。")

def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description='检查用户迁移状态')
    parser.add_argument('--verbose', '-v', action='store_true', help='显示详细信息')
    return parser.parse_args()

def main():
    """主函数"""
    args = parse_arguments()
    
    print("🔍 检查用户迁移状态")
    print("=" * 50)
    
    # 加载环境变量
    supabase_url, supabase_key = load_environment()
    
    # 检查Supabase连接
    supabase = check_supabase_connection(supabase_url, supabase_key)
    
    # 统计旧系统用户
    legacy_count = count_legacy_users(supabase)
    print(f"ℹ️  剩余旧系统用户: {legacy_count}")
    
    # 检查数据一致性
    data_consistent = check_data_consistency(supabase)
    if data_consistent:
        print("✅ 数据一致性良好")
    else:
        print("⚠️  数据一致性存在问题")
    
    # 生成报告
    generate_report(legacy_count, data_consistent)
    
    # 提供建议
    if legacy_count > 0:
        print("\n💡 建议:")
        print("1. 继续鼓励用户迁移到新系统")
        print("2. 考虑设置迁移截止日期")
        print("3. 对于长期不活跃的用户，可以考虑批量迁移")

if __name__ == "__main__":
    main()