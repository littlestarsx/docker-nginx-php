FROM alpine:3.11

ENV TIMEZONE Asia/Shanghai

RUN mkdir -p /var/tmp/client_body_temp && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /var/run/nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /etc/nginx/html && \
    mkdir -p /var/run/php && \
    #修改镜像源为国内https://mirrors.ustc.edu.cn/(中科大)／https://mirrors.aliyun.com/(阿里云)／https://mirrors.tuna.tsinghua.edu.cn/(清华)
    #main官方仓库，community社区仓库
    echo https://mirrors.aliyun.com/alpine/v3.11/main > /etc/apk/repositories && \
    echo https://mirrors.aliyun.com/alpine/v3.11/community >> /etc/apk/repositories && \
    #更新系统和修改时区以及一些扩展
    apk update && apk add --no-cache tzdata curl wget bash git vim openssh && \
    #配置ll alias 命令
    echo "alias ll='ls -l --color=tty'" >> /etc/profile && \
    echo "source /etc/profile " >> ~/.bashrc && \
    #-X获取指定仓库的包
    apk add --no-cache -X http://mirrors.aliyun.com/alpine/v3.11/community neofetch && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    chmod -R 777 /var/tmp/client_body_temp

#nginx镜像echo模块
RUN apk add --no-cache nginx nginx-mod-http-echo

#PHP7和扩展镜像
RUN apk add --no-cache build-base php7 php7-dev php7-fpm php7-common php7-pdo php7-pdo_mysql php7-mysqli php7-curl php7-gd php7-mcrypt php7-openssl php7-json php7-pear php7-phar php7-ctype php7-zip php7-zlib php7-iconv php7-amqp php7-redis php7-mbstring php7-tokenizer unixodbc unixodbc-dev

#composer国内镜像
RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    #设置中国镜像源
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

#nginx配置
COPY nginx-config /etc/nginx/
COPY html /etc/nginx/html/
#php配置
COPY php-config/conf /etc/php7/
#COPY php-config/modules /usr/lib/php7/modules/
#shell脚本
COPY shell /shell
RUN cd /shell && chmod -R 777 /shell

#健康检查 --interval检查的间隔 超时timeout retries失败次数
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl --fail http://localhost || exit 1

#开放端口
EXPOSE 80 443 9000

#启动
CMD ["/shell/start.sh"]
