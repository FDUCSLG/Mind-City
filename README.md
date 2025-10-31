
# Mind-City 构建知识分享的心灵都市🏙️

![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)
![Flarum](https://img.shields.io/badge/Flarum-1.8.x-orange?logo=flarum)
![PHP](https://img.shields.io/badge/PHP-8.3-purple?logo=php)
![License](https://img.shields.io/badge/License-MIT-green)

一个基于 Flarum 构建的现代化社区论坛系统, 专为知识分享和社区交流设计

## 🌟 项目特色

核心功能
- 现代化论坛系统 - 基于 Flarum 1.8.x 构建
- 多语言支持 - 内置简体中文语言包
- 响应式设计 - 完美支持桌面端和移动端浏览器
- SSL 证书 - 自动申请和续期 Let's Encrypt 证书
- 高性能架构 - Nginx + PHP-FPM + MySQL 优化配置

丰富的插件生态
- 内容管理: 标签、审核、举报、封禁系统
- 社交功能: 点赞、关注、提及、实时推送
- 内容增强: Markdown、数学公式、代码高亮、表情包
- 用户互动: 投票、草稿箱、最佳回复、用户徽章
- 实用工具: 文件上传、SEO优化、站点地图、内容过滤
- 货币系统: 虚拟货币、签到、付费阅读、转账功能

## 🚀 快速开始

### 环境要求
- Docker & Docker Compose
- 域名 (mind-city.com, mind-city.cn 等)
- 服务器配置建议: 2核4G或更高 推荐非大陆地区服务器

### 脚本快速部署

```sh
# 根据提示来配置环境
sudo bash start.sh pre

# 方式一: 从头部署 (从空数据库搭建)
sudo bash start.sh deploy-dev

# 方式二: 最新部署 (从最新备份恢复)
sudo bash start.sh deploy-latest

# 方式三: 回滚到指定版本
sudo bash start.sh deploy-back ethancao16770/mind-city:20251030-153138 flarum-db-20251030-153136.sql.gz

# 配置cron (每周日凌晨2点执行备份和同步)
sudo crontab -e
0 2 * * 0 cd /home/ethan/Mind-City && bash start.sh bs >> /var/log/mind-city-cron.log 2>&1
```

## 🔧 管理命令

```sh
# 备份数据库并同步镜像
sudo bash start.sh bs

# 停止并清理所有服务
sudo bash start.sh down

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs flarum
docker compose logs mysql
```

## 📁 项目结构

```sh
Mind-City/
├── docker/
│   ├── flarum.conf          # Nginx 配置文件
│   └── start.sh             # 容器启动脚本
├── database/                # 数据库备份目录
├── composer.json            # PHP依赖配置
├── docker-compose.yml       # Docker编排文件
└── start.sh                 # 部署管理脚本
```

## ⚙️ 配置说明

数据库配置
- 数据库: flarum_db
- 用户名: flarum_user
- 数据持久化: /data/mysql

SSL 证书
- 自动申请 Let's Encrypt 证书
- 自动续期（每日检查）
- 支持多域名配置

备份策略
- 自动备份到腾讯云 COS
- 保留最近 5 个备份版本
- 支持本地和远程备份恢复

## 🛠️ 插件列表

核心插件
- flarum/core - Flarum 核心
- flarum/tags - 标签系统
- flarum-lang/chinese-simplified - 简体中文包

内容管理
- flarum/approval - 内容审核
- flarum/flags - 举报系统
- fof/pages - 静态页面
- fof/links - 友情链接

社交功能
- flarum/likes - 点赞功能
- flarum/mentions - 提及用户
- ianm/follow-users - 关注用户
- fof/oauth - 第三方登录

内容增强
- flarum/markdown - Markdown 支持
- the-turk/flarum-mathren - 数学公式
- fof/formatting - 表格支持
- nearata/flarum-ext-copy-code-to-clipboard - 代码复制

实用工具
- fof/upload + gbcl/fof-upload-qcloud - 腾讯云文件上传
- fof/sitemap - 站点地图
- v17development/flarum-seo - SEO 优化
- hamcq/filter-plus - 内容过滤

货币系统
- antoinefr/flarum-ext-money - 货币系统
- ziiven/flarum-daily-check-in - 每日签到
- xypp/pay-to-read - 付费阅读
- ziiven/money-transfer - 货币转账

📊 监控与统计
- flarum/statistics - 基础统计
- fof/discussion-views - 帖子浏览量
- michaelbelgium/flarum-profile-views - 用户主页浏览量

🎨 界面优化
- acpl/mobile-tab - 移动端标签栏
- flarumtr/flarum-ext-mobile-search - 移动端搜索优化
- nearata/flarum-ext-tags-color-generator - 标签颜色生成器

🔒 安全特性
- 自动SSL证书管理
- 内容审核机制
- 用户权限控制
- 临时邮箱屏蔽
- reCAPTCHA 验证
- 内容安全过滤

## 🙏 致谢

- 优秀的开源论坛软件: https://flarum.org
- 丰富且强大的插件生态: https://github.com/FriendsOfFlarum
- 所有插件开发者们的贡献: https://github.com/realodix/awesome-flarum

## 🤝 贡献指南

本项目基于 MIT 许可证开源  
欢迎提交 Issue 和 Pull Request 来帮助改进 Mind-City 论坛项目

