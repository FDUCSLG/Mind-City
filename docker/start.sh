#!/bin/bash
set -e  # 命令失败立即退出

# 启动 PHP-FPM
echo "$(date) - 启动 PHP-FPM..."
/usr/sbin/php-fpm8.3 --nodaemonize &

# 申请 SSL 证书 (失败则终止容器)
if [ ! -f "/etc/letsencrypt/live/mind-city.com/fullchain.pem" ]; then
    echo "$(date) - 尝试申请证书..."
    certbot certonly --standalone \
        -d mind-city.com \
        -d www.mind-city.com \
        -d mind-city.cn \
        -d www.mind-city.cn \
        --register-unsafely-without-email \
        --agree-tos \
        --non-interactive || {
            echo "$(date) - ❌ 证书申请失败！"
            exit 1  # 终止脚本，容器将停止
        }
    echo "$(date) - ✅ 证书申请成功！"
fi

# 设置证书自动续期
echo "$(date) - 设置证书自动续期..."
echo "0 0 * * * certbot renew --nginx --non-interactive --post-hook 'nginx -s reload'" > /etc/cron.d/certbot
chmod 644 /etc/cron.d/certbot

# 启动 cron 服务
echo "$(date) - 启动 cron 服务..."
cron

# 启动 Nginx (前台运行)
echo "$(date) - 启动 Nginx..."
exec nginx -g "daemon off;"