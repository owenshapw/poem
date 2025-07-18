"""
混合认证中间件 - 支持旧JWT和新Supabase Auth
用于平滑迁移期间的兼容性
"""
from functools import wraps
from flask import request, jsonify, g, current_app
from models.supabase_auth_client import supabase_auth_client
from models.supabase_client import supabase_client
import jwt
import logging

logger = logging.getLogger(__name__)

def hybrid_auth_required(f):
    """
    混合认证装饰器
    同时支持旧的JWT token和新的Supabase Auth token
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # 获取Authorization header
        auth_header = request.headers.get('Authorization')
        
        if not auth_header:
            return jsonify({'error': '缺少认证信息'}), 401
        
        # 检查Bearer token格式
        if not auth_header.startswith('Bearer '):
            return jsonify({'error': '认证格式错误'}), 401
        
        # 提取token
        token = auth_header.split(' ')[1]
        
        # 首先尝试新的Supabase Auth验证
        supabase_result = supabase_auth_client.verify_token(token)
        
        if supabase_result['success'] and supabase_result['valid']:
            # 新的Supabase Auth token有效
            g.current_user = supabase_result['user']
            g.access_token = token
            g.auth_type = 'supabase'
            logger.info(f"用户使用Supabase Auth登录: {g.current_user.email}")
            return f(*args, **kwargs)
        
        # 尝试旧的JWT验证
        try:
            logger.info(f"Supabase Auth验证失败，尝试旧JWT验证")
            payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
            user_id = payload['user_id']
            
            logger.info(f"JWT解码成功，用户ID: {user_id}")
            
            # 从旧的用户表获取用户信息
            old_user = supabase_client.get_user_by_id(user_id)
            
            if old_user:
                logger.info(f"找到旧用户: {old_user.get('email', 'unknown')}, ID: {user_id}")
                # 创建兼容的用户对象
                class CompatUser:
                    def __init__(self, user_data):
                        self.id = user_data['id']
                        self.email = user_data['email']
                        self.user_metadata = {'username': user_data.get('username', '')}
                        self.email_confirmed_at = user_data.get('created_at')  # 假设已确认
                        self.created_at = user_data.get('created_at')
                
                g.current_user = CompatUser(old_user)
                g.access_token = token
                g.auth_type = 'legacy'
                
                # 记录旧系统使用情况，用于迁移监控
                logger.warning(f"用户仍在使用旧认证系统: {old_user['email']}")
                
                return f(*args, **kwargs)
            else:
                return jsonify({'error': '用户不存在'}), 404
                
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token已过期，请重新登录'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token无效'}), 401
        except Exception as e:
            logger.error(f"认证验证异常: {e}")
            return jsonify({'error': '认证验证失败'}), 401
    
    return decorated_function

def get_current_user():
    """
    获取当前认证用户（兼容新旧系统）
    """
    return getattr(g, 'current_user', None)

def get_current_user_id():
    """
    获取当前用户ID（兼容新旧系统）
    """
    user = get_current_user()
    return user.id if user else None

def get_auth_type():
    """
    获取当前认证类型
    """
    return getattr(g, 'auth_type', None)

def is_legacy_user():
    """
    检查是否为旧系统用户
    """
    return get_auth_type() == 'legacy'

def suggest_migration():
    """
    为旧系统用户返回迁移建议
    """
    if is_legacy_user():
        return {
            'migration_suggested': True,
            'message': '为了更好的安全性和用户体验，建议您更新到新的认证系统',
            'migration_url': '/auth/migrate'
        }
    return {'migration_suggested': False}