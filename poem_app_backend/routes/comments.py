from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
from utils.hybrid_auth_middleware import hybrid_auth_required, get_current_user_id, get_current_user
import logging

logger = logging.getLogger(__name__)
comments_bp = Blueprint('comments', __name__)

def ensure_supabase():
    if supabase_client.supabase is None:
        supabase_client.init_app(current_app)

@comments_bp.route('/comments', methods=['POST'])
@hybrid_auth_required
def create_comment():
    """发表评论"""
    try:
        current_user_id = get_current_user_id()
        current_user = get_current_user()
        
        data = request.get_json()
        article_id = data.get('article_id')
        content = data.get('content')
        
        if not article_id or not content:
            return jsonify({'error': '文章ID和评论内容不能为空'}), 400
        
        # 检查文章是否存在
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 创建评论
        comment = supabase_client.create_comment(article_id, current_user_id, content)
        if not comment:
            return jsonify({'error': '评论创建失败'}), 500
        
        return jsonify({
            'message': '评论发表成功',
            'comment': {
                'id': comment['id'],
                'content': comment['content'],
                'author_email': current_user.email,
                'author_username': current_user.user_metadata.get('username', '') if current_user.user_metadata else '',
                'created_at': comment['created_at']
            }
        }), 201
        
    except Exception as e:
        logger.error(f"创建评论异常: {e}")
        return jsonify({'error': str(e)}), 500

@comments_bp.route('/articles/<article_id>/comments', methods=['GET'])
def get_article_comments(article_id):
    """获取文章的所有评论"""
    try:
        # 检查文章是否存在
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 获取评论
        comments = supabase_client.get_comments_by_article(article_id)
        
        # 格式化评论数据
        formatted_comments = []
        for comment in comments:
            comment_author = supabase_client.get_user_by_id(comment['user_id'])
            formatted_comments.append({
                'id': comment['id'],
                'content': comment['content'],
                'author_email': comment_author['email'] if comment_author else '',
                'created_at': comment['created_at']
            })
        
        return jsonify({
            'comments': formatted_comments,
            'total': len(formatted_comments)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@comments_bp.route('/comments/<comment_id>', methods=['DELETE'])
@hybrid_auth_required
def delete_comment(comment_id):
    """删除评论（仅评论者可删除）"""
    try:
        current_user_id = get_current_user_id()
        ensure_supabase()
        
        # 获取评论信息
        comment = supabase_client.get_comment_by_id(comment_id)
        if not comment:
            return jsonify({'error': '评论不存在'}), 404
        
        # 检查是否为评论者
        if comment['user_id'] != current_user_id:
            return jsonify({'error': '无权限删除此评论'}), 403
        
        # 删除评论
        delete_result = supabase_client.delete_comment(comment_id)
        if not delete_result.data:
            return jsonify({'error': '删除失败'}), 500
        
        return jsonify({'message': '评论删除成功'}), 200
    except Exception as e:
        logger.error(f"删除评论异常: {e}")
        return jsonify({'error': str(e)}), 500 