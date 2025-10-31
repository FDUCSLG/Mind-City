#!/bin/bash

# 遇到错误立即退出
set -e

# 切换到脚本所在目录
cd "$(dirname "$(realpath "$0")")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 变量配置
COMPOSE_FILE="docker-compose.yml"
LOG_FILE="/var/log/mind-city-start.log"

COSCMD="/root/.local/bin/coscmd"
BACKUP_DIR="./database"
COS_BUCKET_PATH="/database" # 腾讯云COS上的备份路径
MAX_BACKUP_COUNT=5          # 最大备份文件数量

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

# 颜色输出函数
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    log "[INFO] $1"
}
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    log "[WARN] $1"
}
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "[ERROR] $1"
    exit 1
}

# 准备运行环境
prepare_env() {
    command -v docker >/dev/null 2>&1 || error "Docker 未安装"

    if docker info 2>/dev/null | grep -q "Username"; then
        info "Docker 已登录"
    else
        error "Docker 未登录, 请先运行 'sudo docker login'"
    fi

    if [ -f "$COSCMD" ] >/dev/null 2>&1; then
        if "$COSCMD" probe >/dev/null 2>&1; then
            info "coscmd 已安装且可访问COS"
        else
            error "coscmd 已安装但不可访问COS, 请先修改 'sudo vi /root/.cos.conf'"
        fi
    else
        error "coscmd 未安装, 请先安装 'sudo apt install -y pipx && sudo pipx install coscmd'"
    fi
}

# 方法1: 从头部署
deploy_dev() {
    local image_name="ethancao16770/mind-city:dev"
    info "开始从头部署: 镜像 $image_name"

    deploy "$image_name"
    info "等待数据库初始化..."
    sleep 10
}

# 方法2: 最新部署
deploy_latest() {
    local image_name="ethancao16770/mind-city:latest"
    info "开始最新部署: 镜像 $image_name 和最新数据库备份"

    info "在腾讯云COS查找最新备份..."
    local remote_files=$("$COSCMD" list -r "$COS_BUCKET_PATH" | grep -E "flarum-db-.*\.sql\.gz" | awk '{print $1}' | sort -r || true)
    if [ -z "$remote_files" ]; then
        error "没有找到COS任何数据库备份"
    fi
    local backup_filename=$(basename "$(echo "$remote_files" | head -n1)")
    info "找到COS最新备份: $backup_filename"

    deploy_back "$image_name" "$backup_filename"
}

# 方法3: 回滚部署
deploy_back() {
    local image_name="$1"
    local backup_filename="$2"
    if [ -z "$image_name" ] || [ -z "$backup_filename" ]; then
        error "使用方法: $0 deploy-back <镜像名称> <备份文件名>"
    fi
    info "开始回滚部署: 镜像 $image_name 和备份 $backup_filename"

    local local_path="$BACKUP_DIR/$backup_filename"
    if [ ! -f "$local_path" ]; then
        info "本地未找到备份 $backup_filename, 尝试从COS下载..."
        local remote_path="$COS_BUCKET_PATH/$backup_filename"
        if "$COSCMD" download "$remote_path" "$local_path" >/dev/null 2>&1; then
            info "备份下载成功: $backup_filename"
        else
            error "备份下载失败：$backup_filename"
        fi
    else
        info "使用本地备份: $backup_filename"
    fi

    deploy "$image_name"
    info "等待数据库初始化..."
    sleep 10

    info "检查数据库连接..."
    for i in {1..30}; do
        if docker exec mysql-prod mysql -u root -pflarum_password -e "SELECT 1;" >/dev/null 2>&1; then
            info "数据库连接成功"
            break
        fi
        if [ "$i" -eq 30 ]; then
            error "数据库连接超时"
        fi
        info "尝试第${i}次连接失败, 2秒后重试..."
        sleep 2
    done

    info "从备份恢复数据库..."
    gunzip -c "$local_path" | docker exec -i mysql-prod mysql -u root -pflarum_password flarum_db

    if [[ $? -eq 0 ]]; then
        info "数据恢复成功, 重启flarum容器..."
        docker compose restart flarum
    else
        error "数据恢复失败"
    fi
}

deploy() {
    image_name="$1"
    cat >"$COMPOSE_FILE" <<EOF
services:
    mysql:
        image: mysql:8.0
        container_name: mysql-prod
        restart: unless-stopped
        environment:
            MYSQL_ROOT_PASSWORD: flarum_password
            MYSQL_DATABASE: flarum_db
            MYSQL_USER: flarum_user
            MYSQL_PASSWORD: flarum_password
            TZ: Asia/Shanghai
        volumes:
            - /data/mysql:/var/lib/mysql
        networks:
            - flarum-network

    flarum:
        image: $image_name
        container_name: flarum-prod
        restart: unless-stopped
        depends_on:
            - mysql
        ports:
            - "80:80"
            - "443:443"
        networks:
            - flarum-network

networks:
    flarum-network:
        driver: bridge
EOF

    rm -rf /data/mysql
    mkdir -p /data/mysql "$BACKUP_DIR"
    chown -R 999:999 /data/mysql

    info "启动容器服务..."
    docker compose -f "$COMPOSE_FILE" up -d
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        info "容器部署成功!"
    else
        error "容器部署失败, 请检查日志"
    fi
}

# 备份和同步到DockerHub
backup_and_sync() {
    info "开始备份和同步操作..."
    info "停止论坛服务以确保数据一致性..."
    docker compose -f "$COMPOSE_FILE" stop flarum
    for i in {1..5}; do
        sleep 2
        if ! docker compose -f "$COMPOSE_FILE" ps flarum | grep -q "Up"; then
            info "成功停止flarum容器"
            break
        fi
        if [ "$i" -eq 5 ]; then
            error "无法停止flarum容器, 请手动检查"
        fi
        info "第${i}次检查失败, 2秒后重试..."
    done

    info "开始执行数据库导出..."
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="flarum-db-$timestamp.sql.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    docker compose exec mysql mysqldump \
        -u root -pflarum_password \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        flarum_db | gzip >"$backup_path"

    if [[ $? -eq 0 ]]; then
        local size=$(du -h "$backup_path" | cut -f1)
        info "本地备份成功: $backup_path (大小: $size)"

        local cos_file="$COS_BUCKET_PATH/$(basename $backup_path)"
        info "上传备份到腾讯云COS: $cos_file"
        if "$COSCMD" upload "$backup_path" "$cos_file" >/dev/null 2>&1; then
            info "腾讯云备份成功: $cos_file"
        else
            error "腾讯云备份失败: $cos_file"
        fi

        cleanup_old_backups
        info "数据备份成功完成"
    else
        warn "数据库备份失败, 重启flarum容器..."
        docker compose -f "$COMPOSE_FILE" start flarum
        error "数据库备份失败"
    fi

    info "开始同步容器镜像到 DockerHub..."
    local image_name="ethancao16770/mind-city-prod:$timestamp"
    local latest_name="ethancao16770/mind-city:latest"

    docker commit flarum-prod "$image_name" || {
        error "构造容器镜像失败"
    }
    docker tag "$image_name" "$latest_name"

    info "推送镜像到 DockerHub..."
    docker push "$image_name"
    docker push "$latest_name"

    info "清理本地镜像..."
    docker rmi "$image_name" "$latest_name" 2>/dev/null || true

    info "重启flarum容器..."
    docker compose -f "$COMPOSE_FILE" start flarum

    sleep 3
    if docker compose -f "$COMPOSE_FILE" ps flarum | grep -q "Up"; then
        info "flarum容器启动成功"
    else
        error "flarum容器启动出错, 请检查日志"
    fi
}

# 备份结束后 清理多余旧文件
cleanup_old_backups() {
    info "清理本地旧备份文件..."
    local backup_pattern="$BACKUP_DIR/flarum-db-*.sql.gz"
    local local_backups=($(ls -t $backup_pattern 2>/dev/null || true))
    if [ ${#local_backups[@]} -gt $MAX_BACKUP_COUNT ]; then
        local backups_to_remove=($(ls -tr $backup_pattern 2>/dev/null | head -n -$MAX_BACKUP_COUNT))
        for old_backup in "${backups_to_remove[@]}"; do
            rm -f "$old_backup"
            info "删除本地旧备份: $(basename "$old_backup")"
        done
    fi

    info "清理远程旧备份文件..."
    local remote_files=$("$COSCMD" list -r "$COS_BUCKET_PATH" | grep "flarum-db-.*\.sql\.gz" | awk '{print $1}' | sort -r || true)
    if [ -n "$remote_files" ]; then
        local remote_count=$(echo "$remote_files" | wc -l)
        if [ $remote_count -gt $MAX_BACKUP_COUNT ]; then
            local files_to_remove=$(echo "$remote_files" | tail -n +$(($MAX_BACKUP_COUNT + 1)))
            while IFS= read -r file; do
                if [ -n "$file" ]; then
                    "$COSCMD" delete -y "$file" >/dev/null 2>&1 &&
                        info "删除远程旧备份: $file" ||
                        error "删除远程备份失败: $file"
                fi
            done <<<"$files_to_remove"
        fi
    fi
}

# 停止并清理容器
stop_and_clean() {
    info "停止并清理所有容器和卷..."
    docker compose -f "$COMPOSE_FILE" down -v
    info "容器和卷已清理完成"
}

# 主函数
main() {
    case "${1:-}" in
    "pre")
        prepare_env
        ;;
    "deploy-dev")
        deploy_dev
        ;;
    "deploy-latest")
        deploy_latest
        ;;
    "deploy-back")
        deploy_back "$2" "$3"
        ;;
    "bs")
        backup_and_sync
        ;;
    "down")
        stop_and_clean
        ;;
    *)
        echo "用法: sudo bash $0 [命令] [参数...]"
        echo ""
        echo "命令:"
        echo "  pre                              - 准备环境"
        echo "  deploy-dev                       - 从头部署 (dev)"
        echo "  deploy-latest                    - 最新部署 (latest+最新备份)"
        echo "  deploy-back <mirror> <file>      - 回滚部署 (指定镜像+指定备份)"
        echo "  bs                               - 进行备份和同步"
        echo "  down                             - 停止并清理容器和卷"
        echo ""
        echo "示例:"
        echo -e "  sudo bash $0 deploy-dev"
        echo -e "  sudo bash $0 deploy-latest"
        echo -e "  sudo bash $0 deploy-back \ \n\tethancao16770/mind-city:20251030-153138 \ \n\tflarum-db-20251030-153136.sql.gz"
        echo -e "  sudo bash $0 bs"
        echo -e "  sudo bash $0 down"
        exit 1
        ;;
    esac
}

# 执行主函数
main "$@"
