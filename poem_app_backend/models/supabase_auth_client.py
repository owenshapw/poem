"""
Supabase认证客户端 - 使用Supabase Auth服务
符合Supabase安全策略和RLS要求
"""
from supabase.client import create_client, Client
from gotrue.errors import AuthError
import os
import uuid
from datetime import datetime
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

class SupabaseAuthClient:
    def __init__(self):
        self.supabase: Optional[Client] = None

    def init_app(self, app):
        """初始化Supabase客户端"""
        self.supabase = create_client(
            app.config['SUPABASE_URL'],
            app.config['SUPABASE_KEY']
        )

    def sign_up(self, email: str, password: str, username: str = None) -> Dict[str, Any]:
        """
        用户注册 - 使用Supabase Auth
        自动发送邮箱验证邮件
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            # 准备用户元数据
            user_metadata = {}
            if username:
                user_metadata['username'] = username
                user_metadata['display_name'] = username
            
            # 使用Supabase Auth注册
            response = self.supabase.auth.sign_up({
                "email": email,
                "password": password,
                "options": {
                    "data": user_metadata
                }
            })
            
            if response.user:
                logger.info(f"用户注册成功: {email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'message': '注册成功，请检查邮箱进行验证'
                }
            else:
                return {
                    'success': False,
                    'error': '注册失败'
                }
                
        except AuthError as e:
            logger.error(f"注册失败: {e}")
            return {
                'success': False,
                'error': str(e)
            }
        except Exception as e:
            logger.error(f"注册异常: {e}")
            return {
                'success': False,
                'error': '注册过程中发生错误'
            }

    def sign_in(self, email: str, password: str) -> Dict[str, Any]:
        """
        用户登录 - 使用Supabase Auth
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            response = self.supabase.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            if response.user and response.session:
                logger.info(f"用户登录成功: {email}")
                return {
                    'success': True,
                    'user': response.user,
                    'session': response.session,
                    'access_token': response.session.access_token,
                    'refresh_token': response.session.refresh_token
                }
            else:
                return {
                    'success': False,
                    'error': '登录失败'
                }
                
        except AuthError as e:
            logger.error(f"登录失败: {e}")
            return {
                'success': False,
                'error': '邮箱或密码错误'
            }
        except Exception as e:
            logger.error(f"登录异常: {e}")
            return {
                'success': False,
                'error': '登录过程中发生错误'
            }

    def sign_out(self, access_token: str) -> Dict[str, Any]:
        """
        用户登出
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            # 设置session
            self.supabase.auth.set_session(access_token, None)
            response = self.supabase.auth.sign_out()
            
            return {
                'success': True,
                'message': '登出成功'
            }
        except Exception as e:
            logger.error(f"登出异常: {e}")
            return {
                'success': False,
                'error': '登出失败'
            }

    def reset_password(self, email: str) -> Dict[str, Any]:
        """
        重置密码 - 发送重置邮件
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            response = self.supabase.auth.reset_password_email(email)
            
            return {
                'success': True,
                'message': '密码重置邮件已发送'
            }
        except AuthError as e:
            logger.error(f"密码重置失败: {e}")
            return {
                'success': False,
                'error': str(e)
            }
        except Exception as e:
            logger.error(f"密码重置异常: {e}")
            return {
                'success': False,
                'error': '发送重置邮件失败'
            }

    def update_password(self, access_token: str, new_password: str) -> Dict[str, Any]:
        """
        更新密码
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            # 设置当前session
            self.supabase.auth.set_session(access_token, None)
            
            response = self.supabase.auth.update_user({
                "password": new_password
            })
            
            if response.user:
                return {
                    'success': True,
                    'message': '密码更新成功'
                }
            else:
                return {
                    'success': False,
                    'error': '密码更新失败'
                }
                
        except AuthError as e:
            logger.error(f"密码更新失败: {e}")
            return {
                'success': False,
                'error': str(e)
            }
        except Exception as e:
            logger.error(f"密码更新异常: {e}")
            return {
                'success': False,
                'error': '密码更新过程中发生错误'
            }

    def get_user(self, access_token: str) -> Dict[str, Any]:
        """
        获取当前用户信息
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            # 设置session
            self.supabase.auth.set_session(access_token, None)
            
            response = self.supabase.auth.get_user()
            
            if response.user:
                return {
                    'success': True,
                    'user': response.user
                }
            else:
                return {
                    'success': False,
                    'error': '获取用户信息失败'
                }
                
        except AuthError as e:
            logger.error(f"获取用户信息失败: {e}")
            return {
                'success': False,
                'error': 'Token无效或已过期'
            }
        except Exception as e:
            logger.error(f"获取用户信息异常: {e}")
            return {
                'success': False,
                'error': '获取用户信息过程中发生错误'
            }

    def refresh_session(self, refresh_token: str) -> Dict[str, Any]:
        """
        刷新session
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            response = self.supabase.auth.refresh_session(refresh_token)
            
            if response.session:
                return {
                    'success': True,
                    'session': response.session,
                    'access_token': response.session.access_token,
                    'refresh_token': response.session.refresh_token
                }
            else:
                return {
                    'success': False,
                    'error': 'Session刷新失败'
                }
                
        except AuthError as e:
            logger.error(f"Session刷新失败: {e}")
            return {
                'success': False,
                'error': 'Refresh token无效或已过期'
            }
        except Exception as e:
            logger.error(f"Session刷新异常: {e}")
            return {
                'success': False,
                'error': 'Session刷新过程中发生错误'
            }

    def verify_token(self, access_token: str) -> Dict[str, Any]:
        """
        验证访问令牌
        """
        if not self.supabase:
            raise RuntimeError("Supabase client not initialized")
        
        try:
            # 设置session并获取用户信息来验证token
            self.supabase.auth.set_session(access_token, None)
            response = self.supabase.auth.get_user()
            
            if response.user:
                return {
                    'success': True,
                    'user': response.user,
                    'valid': True
                }
            else:
                return {
                    'success': False,
                    'valid': False,
                    'error': 'Token无效'
                }
                
        except AuthError as e:
            return {
                'success': False,
                'valid': False,
                'error': 'Token无效或已过期'
            }
        except Exception as e:
            logger.error(f"Token验证异常: {e}")
            return {
                'success': False,
                'valid': False,
                'error': 'Token验证失败'
            }

# 全局实例
supabase_auth_client = SupabaseAuthClient()