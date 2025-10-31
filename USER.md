
# Mind-City

## Docker部署

```bash
# 根据提示来配置环境
sudo bash start.sh pre 

# 集成脚本
sudo bash start.sh

# 配置cron (每周日凌晨2点执行备份和同步)
sudo crontab -e
0 2 * * 0 cd /home/ethan/Mind-City && bash start.sh bs >> /var/log/mind-city-cron.log 2>&1
```

## 手动部署

```bash
# 安装PHP和Composer
sudo apt install -y php-cli php-zip php-curl php-dom php-fileinfo php-gd php-mbstring php-pdo-mysql php-tokenizer acl php-fpm nginx
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -rf composer-setup.php
composer self-update --update-keys
composer diagnose

# [没有项目] 创建Flarum新项目
# mkdir Mind-City && cd Mind-City
# composer create-project flarum/flarum:^1.8.0 .

# [已有项目] 克隆仓库
git clone git@github.com:FDUCSLG/Mind-City.git

# 移动并设置文件权限
sudo mv ~/Mind-City /var/www/Mind-City
cd /var/www/Mind-City && composer install
git config --global --add safe.directory /var/www/Mind-City
sudo chown -R www-data:www-data /var/www/Mind-City
sudo chmod -R 775 /var/www/Mind-City
sudo chmod g+s /var/www/Mind-City/ # 新文件继承所属组
sudo setfacl -R -d -m g:www-data:rwx /var/www/Mind-City # 新文件继承组可写
sudo usermod -aG www-data ethan # 请修改用户名
sudo reboot # 重启刷新所属组

# 配置Nginx (注意fpm版本号)
sudo vi /etc/nginx/sites-available/flarum.conf
sudo ln -s /etc/nginx/sites-available/flarum.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# 安装MySQL
sudo apt install -y mysql-server
sudo cat /etc/mysql/debian.cnf
mysql -u debian-sys-maint -p
CREATE DATABASE flarum_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'flarum_user'@'localhost' IDENTIFIED BY '数据库密码'; # 请修改密码
GRANT ALL PRIVILEGES ON flarum_db.* TO 'flarum_user'@'localhost';
FLUSH PRIVILEGES;

# 配置SSL证书
sudo apt install -y certbot python3-certbot-nginx
sudo certbot certonly --webroot -w /var/www/Mind-City/public -d mind-city.com -d www.mind-city.com -d mind-city.cn -d www.mind-city.cn
sudo certbot --nginx -d mind-city.com -d www.mind-city.com -d mind-city.cn -d www.mind-city.cn --register-unsafely-without-email --agree-tos

# 重启服务
sudo nginx -t
sudo systemctl restart php8.3-fpm nginx

# 完成Flarum安装
Forum Title: Mind-City
MySQL Host: localhost
MySQL Database: flarum_db
MySQL Username: flarum_user
MySQL Password: 数据库密码
Table Prefix: flarum_
```


/etc/nginx/sites-available/flarum.conf
```conf
# 本地测试用例 (http)
server {
    listen 80;
    server_name 118.25.110.62; # 请修改地址
    root /var/www/Mind-City/public;
    index index.php;

    # 导入 Flarum 官方规则
    include /var/www/Mind-City/.nginx.conf;

    # PHP 处理
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 禁止访问敏感文件
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```



## 插件安装

插件合集: https://github.com/realodix/awesome-flarum

```bash
php flarum cache:clear

# 官方扩展
composer require flarum/core # 核心
composer require flarum/tags # 标签

composer require flarum/approval # 内容审核
composer require flarum/flags # 举报小黑屋
composer require flarum/suspend # 封禁用户

composer require flarum/emoji # 表情包
composer require flarum/likes # 点赞
composer require flarum/lock # 锁定归档
composer require flarum/markdown # Markdown支持
composer require flarum/mentions # 提及用户
composer require flarum/pusher # 实时推送
composer require flarum/statistics # 统计
composer require flarum/sticky # 置顶
composer require flarum/subscriptions # 订阅标签

composer require flarum-lang/chinese-simplified # 简体中文语言包
composer require fof/oauth # 第三方登录
composer require fof/formatting # 表格支持
composer require fof/follow-tags # 关注标签
composer require fof/best-answer # 最佳回复
composer require fof/sitemap # 站点地图
composer require fof/pages # 静态页面
composer require fof/links # 友情链接
composer require fof/drafts # 草稿箱
composer require fof/polls # 投票插件
composer require fof/frontpage # 精华帖子
composer require fof/profile-image-crop # 头像裁切
composer require fof/github-autolink # GitHub自动链接
composer require fof/user-directory # 用户列表

composer require fof/disposable-emails # 临时邮箱屏蔽
composer require fof/discussion-views # 帖子浏览量统计
composer require fof/byobu # 群聊系统
composer require fof/user-bio # 用户简介

composer require fof/merge-discussions # 帖子合并
composer require fof/split # 帖子拆分
composer require fof/upload # 文件上传
composer require gbcl/fof-upload-qcloud # 腾讯云文件上传
composer require fof/secure-https # 图片强制HTTPS
composer require fof/socialprofile # 社交资料外部链接

composer require blazite/flarum-turnstile # reCAPTCHA验证
composer require hamcq/filter-plus # 阿里云内容过滤
composer require the-turk/flarum-mathren # Katex数学公式
composer require v17development/flarum-seo # SEO搜索引擎优化
composer require nearata/flarum-ext-signup-confirm-password # 注册二次确认密码
composer require clarkwinkelmann/flarum-ext-emojionearea # Emoji表情选择器
composer require blomstra/user-filter # 作者过滤器
composer require tohsakarat/tags-filter # 标签过滤器
composer require acpl/my-tags # 侧栏我的标签
composer require nearata/flarum-ext-copy-code-to-clipboard # 代码复制按钮
composer require nearata/flarum-ext-tags-color-generator # 标签颜色生成器
composer require blomstra/usercard-stats # 用户主页讨论和评论计数
composer require michaelbelgium/flarum-profile-views # 用户主页浏览量
composer require ianm/follow-users # 关注用户
composer require v17development/flarum-user-badges # 用户徽章
composer require sycho/flarum-profile-cover # 用户主页封面


composer require sycho/flarum-advanced-extension-categories # 扩展分类
composer require miniflar/admin-notepad-widget # 管理员便签

composer require acpl/mobile-tab # 移动端标签栏
composer require flarumtr/flarum-ext-mobile-search # 移动端搜索优化

composer require antoinefr/flarum-ext-money # 论坛货币系统
composer require ziiven/flarum-money-leaderboard # 货币排行榜
composer require ziiven/money-transfer # 货币转账
composer require ziiven/flarum-daily-check-in # 每日签到
composer require xypp/pay-to-read # 付费阅读
```


## 自定义样式

> 站点图标制作: https://favicon.io

```txt
📅连续签到第 [days] 天📅
🎉每日礼包 [reward] 贡献点到账🎉
```

```css
/* 帖子内容样式 */
.Post-body {
    /* 表格样式 */
    table {
        border-collapse: collapse;

        /* 表格头样式 */
        thead th {
            border-bottom: 2px solid #808080;
            padding: 5px 10px;
        }

        /* 表体单元格样式 */
        tbody td {
            border-top: 1px solid #808080;
            padding: 5px 10px;
        }
    }

    /* 保证段落间距 */
    p {
        margin-bottom: 30px;
    }

    /* 段落与列表相邻时向上对齐 */
    p + ol, 
    p + ul {
        margin-top: -24px;
    }

    ol + p,
    ul + p {
        margin-top: 0px;
    }

    h1 {
        font-size: 32px;
        margin-top: 70px;
    }

    h2 {
        font-size: 20px;
        margin-top: 68px;
        margin-bottom: 24px;
    }

    h3 {
        margin-top: 30px;
        margin-bottom: 0px;
    }

    hr {
        margin-top: 30px;
        margin-bottom: 50px;
    }

    /* 无序列表缩进对齐 */
    ul {
        padding-inline-start: 20px;
    }

    /* 列表项内的段落间距清零 */
    li {
        p {
            margin: 0px;
        }
    }

    /* KaTeX中文字符 */
    .cjk_fallback {
        font-size: 14px;
    }
}

/* 第三方登录按钮样式 */
.LogInButtons {
    width: 100%;
    margin: 0px;
}

/* 隐藏横幅关闭按钮 */
.Hero-close {
	display:none;
}

/* 隐藏博客图片 */
.FlarumBlog-Article-Image {
    display: none;
}

/* 替换帖子浏览量图标 */
.fa-eye {
    &:before {
        content: "\f519";
        font-weight: 900;
        display: inline-block;
        font-size: 12px;
        margin-right: 4px;
    }
}

/* 隐藏侧栏标签项 */
.item-tags {
    display: none;
}

/* 货币排行榜 */
.MoneyLeaderboardContainer {
    .MoneyLeaderboardListHeaderRank {
        width: 10%;
    }
    
    .MoneyLeaderboardListItemContainer {
        .MoneyLeaderboardListHeaderRank{
            height: 32px;
        }
        align-items: center;
        .transferHistoryUser {
            display: flex;
            align-items: center;
            gap: 4px;

            margin-right: 10px;
            padding: 8px;
            background-color: #e8ecf3;
            border-radius: 16px;
            
            .Avatar {
                --size: 32px;
            }
            .username {
                font-size: 15px;
                font-weight: bold;
                color: #aaaaaa;
            }
        }
        .MoneyLeaderboardListHeaderMoney {
            font-size: 15px;
            font-weight: bold;
            color: #195fa5;
        }
    }
}

/* 签到后隐藏按钮 */
.CheckInButton--green {
    display: none;
}
```