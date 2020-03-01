#!/bin/bash
# 启动nginx
nginx
# root 启动php-fpm
php-fpm7 -R
tail -f /dev/null
