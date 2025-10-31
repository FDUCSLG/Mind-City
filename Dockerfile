

FROM ubuntu:24.04


# 设置时区
# 安装依赖 (PHP, Nginx, Certbot, Cron, Composer)
# 创建并初始化Flarum项目
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt update && apt install -y \
    curl \
    git \
    unzip \
    php-cli \
    php-zip \
    php-curl \
    php-dom \
    php-fileinfo \
    php-gd \
    php-mbstring \
    php-pdo-mysql \
    php-tokenizer \
    php-fpm \
    nginx \
    certbot \
    python3-certbot-nginx \
    cron \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php \
    && mkdir /Mind-City && cd /Mind-City \
    && composer create-project flarum/flarum:^1.8.0 .

# 复制Flarum插件和Nginx配置文件
COPY ./composer.json /Mind-City/composer.json
COPY ./docker/flarum.conf /etc/nginx/sites-available/flarum.conf

# 安装Flarum插件和配置Nginx
RUN cd /Mind-City \
    && rm -f composer.lock \
    && composer install \
    && chown -R www-data:www-data /Mind-City \
    && ln -s /etc/nginx/sites-available/flarum.conf /etc/nginx/sites-enabled/flarum.conf \
    && rm -f /etc/nginx/sites-enabled/default

# 复制启动脚本
COPY ./docker/start.sh /start.sh
RUN chmod +x /start.sh

# 暴露端口
EXPOSE 80 443

# 设置容器启动脚本
CMD ["/start.sh"]