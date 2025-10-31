#!/bin/bash
set -e

# 创建日志目录
mkdir -p /var/log
touch /var/log/startup.log
chmod 644 /var/log/startup.log

# 检查是否存在证书，如果不存在则生成自签名证书
if [ ! -f "/etc/ssl/private/mind-city.key" ]; then
    echo "$(date) - 生成自签名证书..."
    mkdir -p /etc/ssl/private /etc/ssl/certs
    
    # 生成自签名证书（有效期为365天）
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/mind-city.key \
        -out /etc/ssl/certs/mind-city.crt \
        -subj "/C=CN/ST=Beijing/L=Beijing/O=Dev/CN=mind-city.com" \
        -addext "subjectAltName=DNS:mind-city.com,DNS:www.mind-city.com,DNS:mind-city.cn,DNS:www.mind-city.cn"
    
    echo "$(date) - ✅ 自签名证书生成成功！"
fi

# 修改 Nginx 配置使用自签名证书
sed -i 's#/etc/letsencrypt/live/mind-city.com/fullchain.pem#/etc/ssl/certs/mind-city.crt#g' /etc/nginx/sites-available/flarum.conf
sed -i 's#/etc/letsencrypt/live/mind-city.com/privkey.pem#/etc/ssl/private/mind-city.key#g' /etc/nginx/sites-available/flarum.conf

# 启动 PHP-FPM
echo "$(date) - 启动 PHP-FPM..."
/usr/sbin/php-fpm8.3 --nodaemonize &

# 启动 Nginx
echo "$(date) - 启动 Nginx..."
exec nginx -g "daemon off;"