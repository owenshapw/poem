"""
认证中间件 - 用于保护需要认证的路由
使用Supabase Auth token验证
"""
from functools import wraps
from flask import request, jsonify, g
from models.supabase_auth_client import supabase_auth_client
import logging

logger = logging.getLogger(__name__)

def require_auth(f):
    """
    装饰器：要求用户认证
    从Authorization header中提取Bearer token并验证
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
        access_token = auth_header.split(' ')[1]
        
        # 验证token
        result = supabase_auth_client.verify_token(access_token)
        
        if not result['success'] or not result['valid']:
            return jsonify({'error': result.get('error', 'Token无效')}), 401
        
        # 将用户信息存储到g对象中，供路由函数使用
        g.current_user = result['user']
        g.access_token = access_token
        
        return f(*args, **kwargs)
    
    return decorated_function

def get_current_user():
    """
    获取当前认证用户
    """
    return getattr(g, 'current_user', None)

def get_current_user_id():
    """
    获取当前用户ID
    """
    user = get_current_user()
    return user.id if user else None

def get_access_token():
    """
    获取当前访问令牌
    """
    return getattr(g, 'access_token', None)

def optional_auth(f):
    """
    装饰器：可选认证
    如果提供了token则验证，否则继续执行
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # 获取Authorization header
        auth_header = request.headers.get('Authorization')
        
        if auth_header and auth_header.startswith('Bearer '):
            # 提取token
            access_token = auth_header.split(' ')[1]
            
            # 验证token
            result = supabase_auth_client.verify_token(access_token)
            
            if result['success'] and result['valid']:
                # 将用户信息存储到g对象中
                g.current_user = result['user']
                g.access_token = access_token
            else:
                # token无效，但不阻止访问
                g.current_user = None
                g.access_token = None
        else:
            # 没有提供token
            g.current_user = None
            g.access_token = None
        
        return f(*args, **kwargs)
    
    return decorated_function