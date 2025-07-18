from flask import Blueprint, jsonify, request
from utils.cloudflare_client import cloudflare_client
import re

cloudflare_bp = Blueprint('cloudflare', __name__)

@cloudflare_bp.route('/api/cloudflare/status', methods=['GET'])
def cloudflare_status():
    """检查 Cloudflare Images 状态"""
    try:
        is_available = cloudflare_client.is_available()
        return jsonify({
            'available': is_available,
            'account_id': cloudflare_client.account_id if is_available else None,
            'message': 'Cloudflare Images 可用' if is_available else 'Cloudflare Images 不可用'
        })
    except Exception as e:
        return jsonify({
            'available': False,
            'error': str(e)
        }), 500

@cloudflare_bp.route('/api/cloudflare/list', methods=['GET'])
def cloudflare_list():
    """列出 Cloudflare Images 中的文件"""
    try:
        if not cloudflare_client.is_available():
            return jsonify({'error': 'Cloudflare Images 不可用'}), 500
        
        max_files = request.args.get('max_files', 10, type=int)
        files = cloudflare_client.list_files(max_files)
        
        return jsonify({
            'files': files,
            'count': len(files)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cloudflare_bp.route('/api/cloudflare/upload', methods=['POST'])
def cloudflare_upload():
    """测试 Cloudflare Images 上传"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file part'}), 400
        
        file = request.files['file']
        if not file or not file.filename:
            return jsonify({'error': 'No selected file'}), 400
        
        if not cloudflare_client.is_available():
            return jsonify({'error': 'Cloudflare Images 不可用'}), 500
        
        file_data = file.read()
        content_type = file.content_type or 'application/octet-stream'
        
        public_url = cloudflare_client.upload_file(
            file_data,
            file.filename,
            content_type
        )
        
        def _format_image_url(url):
            if not url:
                return url
            m = re.search(r'imagedelivery\.net/[^/]+/([\w-]+)/public', url)
            if m:
                image_id = m.group(1)
                return f"https://images.shipian.app/images/{image_id}/public"
            return url

        if public_url:
            return jsonify({
                'message': '文件上传成功',
                'url': _format_image_url(public_url)
            })
        else:
            return jsonify({'error': '文件上传失败'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500 