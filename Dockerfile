FROM alpine:3.15

#设置时区
ENV TIMEZONE Asia/Shanghai

#Dockerfile 的指令每执行一次都会在 docker 上新建一层。所以过多无意义的层，会造成镜像膨胀过大
RUN mkdir -p /var/tmp/client_body_temp && \
    mkdir -p /var/lib/nginx && \
    mkdir -p /var/run/nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /etc/nginx/html && \
    mkdir -p /var/run/php && \
    #修改镜像源为国内https://mirrors.ustc.edu.cn/(中科大)／https://mirrors.aliyun.com/(阿里云)／https://mirrors.tuna.tsinghua.edu.cn/(清华)
    #main官方仓库 community社区仓库
    echo https://mirrors.ustc.edu.cn/alpine/v3.15/main > /etc/apk/repositories && \
    echo https://mirrors.ustc.edu.cn/alpine/v3.15/community >> /etc/apk/repositories && \
    #更新仓库
    apk update && \
    #安装基础工具
    apk add --no-cache tzdata curl curl-dev wget bash git vim openssh openssl-dev && \
    #安装编译工具及odbc
    apk add --no-cache build-base unixodbc unixodbc-dev && \
    #-X获取指定仓库的包
    apk add --no-cache -X http://mirrors.aliyun.com/alpine/v3.15/community neofetch && \
    #配置ll alias 命令
    echo "alias ll='ls -l --color=tty'" >> /etc/profile && \
    echo "source /etc/profile " >> ~/.bashrc && \
    #设置时区
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    chmod -R 777 /var/tmp/client_body_temp && \
    #安装nginx及echo模块
    apk add --no-cache nginx nginx-mod-http-echo && \
    #安装PHP7及扩展
    apk add --no-cache php7 php7-dev php7-fpm php7-common php7-pdo php7-pdo_mysql php7-mysqli php7-curl php7-gd php7-mcrypt php7-openssl \
    php7-json php7-pear php7-phar php7-ctype php7-zip php7-zlib php7-iconv php7-amqp php7-redis php7-mbstring php7-tokenizer php7-dom \
    php7-simplexml php7-xmlwriter php7-xmlreader php7-sockets php7-fileinfo php7-sodium php7-opcache php7-pcntl && \
    #php配置
    echo "post_max_size=300M" > /etc/php7/conf.d/00_default.ini && \
    echo "upload_max_filesize=200M" >> /etc/php7/conf.d/00_default.ini && \
    echo "date.timezone=Asia/Shanghai" >> /etc/php7/conf.d/00_default.ini && \
    echo "display_errors=Off" >> /etc/php7/conf.d/00_default.ini && \
    echo "log_errors=On" >> /etc/php7/conf.d/00_default.ini && \
    echo "error_log='/var/log/php7/error.log'" >> /etc/php7/conf.d/00_default.ini && \
    echo "error_reporting=E_ALL & ~E_NOTICE & ~E_STRICT" >> /etc/php7/conf.d/00_default.ini && \
    #安装swoole
    cd /tmp && \
    curl -SL "https://github.com/swoole/swoole-src/archive/v4.8.11.tar.gz" -o swoole.tar.gz && \
    mkdir -p swoole && \
    tar -xf swoole.tar.gz -C swoole --strip-components=1 && \
    ( \
        cd swoole && \
        phpize && \
        ./configure --enable-openssl --enable-http2 --enable-swoole-curl --enable-swoole-json && \
        make && make install \
    ) && \
    echo "memory_limit=1G" > /etc/php7/conf.d/00_default.ini && \
    echo "opcache.enable_cli = 'On'" >> /etc/php7/conf.d/00_opcache.ini && \
    echo "extension=swoole.so" > /etc/php7/conf.d/50_swoole.ini && \
    echo "swoole.use_shortname = 'Off'" >> /etc/php7/conf.d/50_swoole.ini && \
    #安装composer
    php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    #配置composer中国镜像源(阿里云)
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

#nginx配置
COPY nginx-config /etc/nginx/
COPY html /etc/nginx/html/

#php配置
COPY php-config/conf/php-fpm.d /etc/php7/php-fpm.d/

#shell脚本
COPY shell /root/shell
RUN cd /root/shell && chmod -R 777 /root/shell

#健康检查 --interval检查间隔 --timeout超时时长 --retries失败次数
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -fs http://localhost/ || exit 1

#开放端口 仅仅只是声明端口实际未定义映射
EXPOSE 80 443 9000

#启动服务
CMD ["/root/shell/start.sh"]
