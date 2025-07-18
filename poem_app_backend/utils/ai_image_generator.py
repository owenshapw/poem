import os
import requests
import json
from PIL import Image
from io import BytesIO
import uuid
from flask import current_app
from models.supabase_client import supabase_client
from supabase.client import create_client
from utils.cloudflare_client import cloudflare_client
import imghdr
import re
from typing import Optional

class AIImageGenerator:
    def __init__(self):
        self.api_url = "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"
        self.api_key = None
        self.hf_api_url = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        self.hf_api_key = None
        self._initialized = False

    def _init_client(self):
        if self._initialized:
            return
        self.api_key = os.environ.get('STABILITY_API_KEY', '')
        self.hf_api_key = os.environ.get('HF_API_KEY', '')
        self._initialized = True

    def generate_prompt_from_poem(self, title, content, tags):
        """根据用户定义的现代抽象风格生成提示词"""
        
        # 核心风格与构图 (线条)
        line_style = "Dynamic and energetic line abstraction, reminiscent of Action Painting and Gesture Drawing, dominant, free-flowing brushstrokes that create a sense of movement"
        
        # 点缀元素 (斑点)
        dot_style = "Subtly accented with speckled textures and a variation of Pointillism, vibrant, colorful dots sparingly placed to enhance the atmosphere"
        
        # 中间色块 (笔刷感)
        color_field_style = "Translucent color fields created with a dry brush texture, revealing layers underneath, light, airy impasto technique for a sense of texture and depth"
        
        # 画布材质
        canvas_style = "The entire image rendered on a raw canvas texture, with the visible grain of the fabric showing through"
        
        # 色彩与氛围
        mood_style = "Bright, luminous, and vibrant color palette, sun-drenched colors, joyful, cheerful, and uplifting mood"
        
        # 构图与留白
        composition_style = "Airy and spacious composition, uncluttered, significant negative space, over 60% of the image is clean white space, especially around the borders"

        # 品质要求
        quality = "high resolution, masterpiece, detailed, artistic"

        # 组合提示词
        prompt = f"{line_style}, {dot_style}, {color_field_style}, {canvas_style}, {mood_style}, {composition_style}, {quality}"
        
        # 负面提示词
        negative_prompt = "dark, gloomy, somber, deep shadows, gray, muted tones, depressing, sad, text, words, letters, low quality, blurry, distorted, ugly, deformed, figurative, representation, landscape, figurative painting, photo, realism"
        
        return prompt, negative_prompt

    def generate_with_stability_ai(self, prompt, negative_prompt):
        if not self.api_key:
            return None
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        data = {
            "text_prompts": [
                {"text": prompt, "weight": 1},
                {"text": negative_prompt, "weight": -1}
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30,
        }
        try:
            response = requests.post(self.api_url, headers=headers, json=data, timeout=30)
            if response.status_code == 200:
                result = response.json()
                if 'artifacts' in result and len(result['artifacts']) > 0:
                    image_data = result['artifacts'][0]['base64']
                    import base64
                    return BytesIO(base64.b64decode(image_data))
        except Exception as e:
            print(f"Stability AI Error: {e}")
        return None

    def generate_with_huggingface(self, prompt, negative_prompt):
        if not self.hf_api_key:
            return None
        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json"
        }
        data = {"inputs": f"{prompt}, {negative_prompt}"}
        try:
            response = requests.post(self.hf_api_url, headers=headers, json=data, timeout=60)
            if response.status_code == 200:
                return BytesIO(response.content)
        except Exception as e:
            print(f"Hugging Face Error: {e}")
        return None

    def _ensure_supabase_initialized(self):
        try:
            if supabase_client.supabase is None:
                supabase_url = os.environ.get('SUPABASE_URL')
                supabase_key = os.environ.get('SUPABASE_KEY')
                if supabase_url and supabase_key:
                    supabase_client.supabase = create_client(supabase_url, supabase_key)
                    return True
                return False
            return True
        except Exception:
            return False

    def _format_image_url(self, url: Optional[str]) -> str:
        if not url:
            return ""
        m = re.search(r'imagedelivery\.net/[^/]+/([\w-]+)/public', url)
        if m:
            image_id = m.group(1)
            return f"https://images.shipian.app/images/{image_id}/headphoto"
        return url

    def generate_poem_image(self, article, user_token=None):
        self._init_client()
        try:
            prompt, negative_prompt = self.generate_prompt_from_poem(
                article['title'], article['content'], article.get('tags', [])
            )
            image_data = self.generate_with_huggingface(prompt, negative_prompt)
            if not image_data:
                image_data = self.generate_with_stability_ai(prompt, negative_prompt)
            
            if image_data:
                image_data.seek(0)
                image_bytes = image_data.read()
                filename = f"ai_generated_{uuid.uuid4().hex}.png"
                
                public_url = None
                if cloudflare_client.is_available():
                    public_url = cloudflare_client.upload_file(image_bytes, filename)
                else:
                    if self._ensure_supabase_initialized() and supabase_client.supabase:
                        bucket = "images"
                        storage_client = supabase_client.supabase.storage
                        storage_client.from_(bucket).upload(filename, image_bytes, {"content-type": "image/png"})
                        public_url = storage_client.from_(bucket).get_public_url(filename)
                
                if public_url:
                    return self._format_image_url(public_url)
        except Exception as e:
            print(f"Generate Poem Image Error: {e}")
        return None

ai_generator = AIImageGenerator()