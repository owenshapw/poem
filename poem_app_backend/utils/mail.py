import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from flask import current_app

def send_email(to_email: str, subject: str, body: str):
    """发送邮件"""
    try:
        # 创建邮件对象
        msg = MIMEMultipart()
        msg['From'] = current_app.config['EMAIL_USERNAME']
        msg['To'] = to_email
        msg['Subject'] = subject
        
        # 添加邮件正文
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
        
        # 连接SMTP服务器
        server = smtplib.SMTP(current_app.config['EMAIL_SERVER'], current_app.config['EMAIL_PORT'])
        server.starttls()
        
        # 登录
        server.login(current_app.config['EMAIL_USERNAME'], current_app.config['EMAIL_PASSWORD'])
        
        # 发送邮件
        text = msg.as_string()
        server.sendmail(current_app.config['EMAIL_USERNAME'], to_email, text)
        
        # 关闭连接
        server.quit()
        
        return True
        
    except Exception as e:
        return False

def send_welcome_email(email: str, username: str):
    """发送欢迎邮件"""
    subject = "欢迎加入诗篇"
    body = f"""
    亲爱的 {username}，
    
    欢迎加入诗篇！这是一个让您的诗词创作绽放光彩的地方。
    
    在这里，您可以：
    - 创作和分享您的诗词文章
    - 享受AI智能排版的美学体验
    - 与其他创作者交流互动
    - 下载精美的图文作品
    
    开始您的创作之旅吧！
    
    诗篇团队
    """
    
    return send_email(email, subject, body)

def send_password_reset_email(email: str, reset_url: str):
    """发送密码重置邮件"""
    subject = "诗篇 - 密码重置"
    body = f"""
    您好，
    
    您请求重置密码。请点击以下链接重置密码：
    
    {reset_url}
    
    此链接将在1小时后失效。
    
    如果这不是您的操作，请忽略此邮件。
    
    诗篇团队
    """
    
    return send_email(email, subject, body) 