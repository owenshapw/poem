#!/usr/bin/env python3
"""
用户数据迁移脚本
将现有用户从自定义认证系统迁移到Supabase Auth
"""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv
import bcrypt
import uuid
from datetime import datetime

def load_environment():
    """加载环境变量"""
    load_dotenv()
    
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ 错误: 请设置 SUPABASE_URL 和 SUPABASE_KEY 环境变量")
        sys.exit(1)
    
    return supabase_url, supabase_key

def get_existing_users(supabase):
    """获取现有用户数据"""
    try:
        # 从旧的users表获取用户数据
        result = supabase.table('users').select('*').execute()
        return result.data
    except Exception as e:
        print(f"❌ 获取现有用户失败: {e}")
        return []

def migrate_user_to_supabase_auth(supabase, user_data):
    """将单个用户迁移到Supabase Auth"""
    try:
        email = user_data.get('email')
        username = user_data.get('username', email.split('@')[0] if email else '')
        
        if not email:
            print(f"⚠️  跳过无邮箱用户: {user_data}")
            return False
        
        # 生成临时密码（用户需要重置）
        temp_password = f"temp_{uuid.uuid4().hex[:8]}"
        
        # 使用Supabase Auth创建用户
        response = supabase.auth.admin.create_user({
            "email": email,
            "password": temp_password,
            "email_confirm": True,  # 直接确认邮箱
            "user_metadata": {
                "username": username,
                "migrated": True,
                "original_id": user_data.get('id'),
                "migration_date": datetime.utcnow().isoformat()
            }
        })
        
        if response.user:
            print(f"✅ 用户迁移成功: {email}")
            return True
        else:
            print(f"❌ 用户迁移失败: {email}")
            return False
            
    except Exception as e:
        print(f"❌ 迁移用户 {user_data.get('email', 'unknown')} 失败: {e}")
        return False

def update_article_user_ids(supabase, old_users, new_users):
    """更新文章表中的用户ID"""
    try:
        # 创建ID映射
        id_mapping = {}
        for old_user in old_users:
            old_id = old_user['id']
            email = old_user['email']
            
            # 找到对应的新用户
            for new_user in new_users:
                if new_user.email == email:
                    id_mapping[old_id] = new_user.id
                    break
        
        # 更新文章表
        for old_id, new_id in id_mapping.items():
            result = supabase.table('articles').update({
                'user_id': new_id
            }).eq('user_id', old_id).execute()
            
            if result.data:
                print(f"✅ 更新文章用户ID: {old_id} -> {new_id}")
        
        return True
        
    except Exception as e:
        print(f"❌ 更新文章用户ID失败: {e}")
        return False

def update_comment_user_ids(supabase, old_users, new_users):
    """更新评论表中的用户ID"""
    try:
        # 创建ID映射
        id_mapping = {}
        for old_user in old_users:
            old_id = old_user['id']
            email = old_user['email']
            
            # 找到对应的新用户
            for new_user in new_users:
                if new_user.email == email:
                    id_mapping[old_id] = new_user.id
                    break
        
        # 更新评论表
        for old_id, new_id in id_mapping.items():
            result = supabase.table('comments').update({
                'user_id': new_id
            }).eq('user_id', old_id).execute()
            
            if result.data:
                print(f"✅ 更新评论用户ID: {old_id} -> {new_id}")
        
        return True
        
    except Exception as e:
        print(f"❌ 更新评论用户ID失败: {e}")
        return False

def send_migration_notification_email(supabase, users):
    """发送迁移通知邮件（可选实现）"""
    print("\n📧 建议发送迁移通知邮件给用户:")
    print("内容应包括:")
    print("- 系统安全升级通知")
    print("- 需要重置密码的说明")
    print("- 新功能介绍")
    print("- 客服联系方式")

def create_migration_report(old_users, migrated_count):
    """创建迁移报告"""
    report_path = "user_migration_report.txt"
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("用户迁移报告\n")
        f.write("=" * 50 + "\n")
        f.write(f"迁移时间: {datetime.utcnow().isoformat()}\n")
        f.write(f"原有用户数: {len(old_users)}\n")
        f.write(f"成功迁移数: {migrated_count}\n")
        f.write(f"迁移成功率: {migrated_count/len(old_users)*100:.1f}%\n\n")
        
        f.write("迁移详情:\n")
        for user in old_users:
            f.write(f"- {user.get('email', 'unknown')}: {user.get('username', 'N/A')}\n")
    
    print(f"📄 迁移报告已保存: {report_path}")

def main():
    """主函数"""
    print("🔄 用户数据迁移脚本")
    print("=" * 50)
    
    # 确认操作
    confirm = input("⚠️  此操作将迁移现有用户到Supabase Auth。是否继续? (y/N): ")
    if confirm.lower() != 'y':
        print("❌ 操作已取消")
        sys.exit(0)
    
    # 加载环境变量
    supabase_url, supabase_key = load_environment()
    
    # 创建Supabase客户端
    try:
        supabase = create_client(supabase_url, supabase_key)
        print("✅ Supabase连接成功")
    except Exception as e:
        print(f"❌ Supabase连接失败: {e}")
        sys.exit(1)
    
    # 获取现有用户
    print("\n📋 获取现有用户数据...")
    old_users = get_existing_users(supabase)
    
    if not old_users:
        print("ℹ️  没有找到需要迁移的用户")
        sys.exit(0)
    
    print(f"📊 找到 {len(old_users)} 个用户需要迁移")
    
    # 迁移用户
    print("\n🔄 开始迁移用户...")
    migrated_count = 0
    
    for user in old_users:
        if migrate_user_to_supabase_auth(supabase, user):
            migrated_count += 1
    
    print(f"\n✅ 用户迁移完成: {migrated_count}/{len(old_users)}")
    
    # 获取新用户列表
    try:
        new_users_response = supabase.auth.admin.list_users()
        new_users = new_users_response.users if hasattr(new_users_response, 'users') else []
    except Exception as e:
        print(f"⚠️  无法获取新用户列表: {e}")
        new_users = []
    
    # 更新关联数据
    if new_users:
        print("\n🔄 更新关联数据...")
        update_article_user_ids(supabase, old_users, new_users)
        update_comment_user_ids(supabase, old_users, new_users)
    
    # 创建迁移报告
    create_migration_report(old_users, migrated_count)
    
    # 发送通知邮件提醒
    send_migration_notification_email(supabase, old_users)
    
    print("\n🎉 迁移完成!")
    print("\n📋 后续步骤:")
    print("1. 通知用户系统升级")
    print("2. 指导用户重置密码")
    print("3. 监控用户反馈")
    print("4. 清理旧的用户表(可选)")

if __name__ == "__main__":
    main()