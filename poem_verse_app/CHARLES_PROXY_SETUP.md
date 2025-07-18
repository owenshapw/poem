# Charles Proxy 网络抓包设置指南

## 问题背景
iOS设备上的Flutter应用无法加载Cloudflare Images，出现"Connection reset by peer"错误。使用Charles Proxy可以捕获详细的网络请求和响应，帮助诊断问题。

## 安装Charles Proxy

### macOS
1. 访问 https://www.charlesproxy.com/
2. 下载并安装Charles Proxy
3. 启动Charles Proxy

### Windows
1. 下载Windows版本的Charles Proxy
2. 安装并启动

## 配置Charles Proxy

### 1. 基础设置
1. 打开Charles Proxy
2. 点击菜单 `Proxy` -> `Proxy Settings`
3. 确保HTTP代理端口为 `8888`
4. 勾选 `Enable transparent HTTP proxying`

### 2. SSL证书设置（重要）
1. 点击菜单 `Help` -> `SSL Proxying` -> `Install Charles Root Certificate`
2. 在macOS上，双击下载的证书文件
3. 在钥匙串访问中，找到Charles证书并设置为"始终信任"
4. 点击菜单 `Proxy` -> `SSL Proxying Settings`
5. 勾选 `Enable SSL Proxying`
6. 添加以下主机：
   - `*.imagedelivery.net`
   - `*.cloudflare.com`
   - `*.myqcloud.com`
   - `*` (用于捕获所有HTTPS流量)

## 配置iOS设备

### 方法1：WiFi代理（推荐）
1. 确保iOS设备和Mac在同一WiFi网络
2. 在Mac上查看IP地址：
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
3. 在iOS设备上：
   - 设置 -> WiFi -> 点击当前网络 -> 配置代理
   - 选择"手动"
   - 服务器：输入Mac的IP地址
   - 端口：8888
4. 在iOS设备上访问 http://charlesproxy.com/getssl
5. 下载并安装Charles证书
6. 设置 -> 通用 -> VPN与设备管理 -> 信任Charles证书

### 方法2：USB连接（需要额外工具）
1. 安装iOS Web Debug Proxy (ios_webkit_debug_proxy)
2. 通过USB连接iOS设备
3. 配置代理转发

## 测试网络连接

### 1. 基础测试
1. 在iOS设备上打开Safari
2. 访问 https://httpbin.org/get
3. 在Charles中查看请求和响应

### 2. Cloudflare Images测试
1. 在iOS设备上访问：
   ```
   https://imagedelivery.net/4RSIo06aA9cYqJB6iDeiUA/92f2a304-8ada-441a-115e-aeaabff62d00/public
   ```
2. 在Charles中观察：
   - 请求是否发送成功
   - 服务器是否返回响应
   - 响应状态码
   - 响应头信息
   - 连接是否被重置

### 3. Flutter应用测试
1. 在Charles中清空所有记录
2. 运行Flutter应用
3. 尝试加载图片
4. 在Charles中查看详细的网络请求

## 分析Charles日志

### 关键信息点
1. **请求头**：
   - User-Agent
   - Accept
   - Accept-Encoding
   - Connection

2. **响应头**：
   - Status Code
   - Content-Type
   - Content-Length
   - Cache-Control

3. **连接状态**：
   - 是否建立TCP连接
   - 是否完成SSL握手
   - 是否发送HTTP请求
   - 是否收到服务器响应

### 常见问题分析

#### 1. 连接被重置 (Connection reset by peer)
- **现象**：TCP连接建立后立即被服务器关闭
- **可能原因**：
  - 防火墙阻止
  - 服务器拒绝特定User-Agent
  - 网络运营商限制
  - Cloudflare安全策略

#### 2. SSL握手失败
- **现象**：无法建立HTTPS连接
- **可能原因**：
  - 证书问题
  - SSL/TLS版本不兼容
  - 代理配置错误

#### 3. DNS解析失败
- **现象**：无法解析域名
- **可能原因**：
  - DNS服务器问题
  - 网络配置错误
  - 运营商DNS劫持

## 解决方案建议

### 1. 更换网络环境
- 尝试手机热点
- 使用VPN
- 更换WiFi网络

### 2. 更换CDN服务
- 阿里云OSS
- 七牛云
- 腾讯云COS
- 本地存储

### 3. 调整请求头
- 修改User-Agent
- 添加Referer
- 调整Accept头

### 4. 使用HTTP代理
- 配置HTTP代理服务器
- 绕过网络限制

## 其他抓包工具

### Wireshark
- 更底层的网络分析
- 可以捕获所有网络包
- 适合深入分析网络问题

### Fiddler
- Windows平台的抓包工具
- 功能类似Charles
- 免费版本可用

### mitmproxy
- 开源的抓包工具
- 支持命令行操作
- 可编程扩展

## 注意事项

1. **隐私安全**：Charles会捕获所有网络流量，注意保护敏感信息
2. **证书信任**：确保正确安装和信任Charles证书
3. **网络影响**：代理可能影响网络性能
4. **法律合规**：仅用于开发和调试，不要用于非法用途

## 故障排除

### Charles无法启动
- 检查端口8888是否被占用
- 尝试更换端口
- 重启Charles

### iOS设备无法连接代理
- 检查IP地址是否正确
- 确认防火墙设置
- 尝试重启网络

### 证书安装失败
- 删除旧证书重新安装
- 检查证书信任设置
- 重启iOS设备 