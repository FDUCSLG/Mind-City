

```sh
# 构建镜像
docker build -t ethancao16770/mind-city:dev .

# 推送镜像
docker login
docker push ethancao16770/mind-city:dev

# 创建网络
docker network create flarum-network

# 启动 MySQL
docker run -d \
    --name mysql-prod \
    --network flarum-network \
    --restart unless-stopped \
    -e MYSQL_ROOT_PASSWORD=flarum_password \
    -e MYSQL_DATABASE=flarum_db \
    -e MYSQL_USER=flarum_user \
    -e MYSQL_PASSWORD=flarum_password \
    -v /data/mysql:/var/lib/mysql \
    mysql:8.0

# 启动 Flarum
docker run -d \
    --name flarum-prod \
    --network flarum-network \
    -p 80:80 \
    -p 443:443 \
    ethancao16770/mind-city:dev


docker run -d \
    --name flarum-prod \
    --network flarum-network \
    -p 80:80 \
    -p 443:443 \
    ethancao16770/mind-city:latest