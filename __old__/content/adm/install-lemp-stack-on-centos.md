---
title: LEMP + CentOS = ❤
date: 2016-06-29T12:03:09+00:00
aliases:
  - /adm/install-lemp-stack-on-centos.html
featured_image: /images/posts/lemp-wide.jpg
tags:
  - bash
  - centos
  - cron
  - iptables
  - linux
  - nginx
  - php
  - shell
  - ssh
---

Данный пост скорее заметка для самого себя, дабы не забыть чего при новой итерации. Нового в ней ничего нет, ставим пакеты да настраиваем. У нас имеется новый и девственно чистый сервер под управлением CentOS 7.2 (minimal). Задача - поставить на него nginx + php + php-fpm + mysql и чтоб всё это шустро работало, да обновлялось самостоятельно из репозиториев (при возможности). Так же необходим тот же phpMyAdmin и настроенная отправка почты с сервера. В общем - минимальный web-stack, на котором хоть разработкой занимайся, хоть что-то вордпресо-подобное разворачивай. Сервер, к слову, располагается на hetzner.de.

<!--more-->

Итак, коннектимся к нему с win-машины с помощью putty:

```bash
putty.exe -ssh -l root -pw %password% -P 22 %ip_address%
```

### Шаг #0 - Текстовый редактор и окружение

Устанавливаем nano:

```bash
$ yum install nano
```

Правим его настройки, выставляя их в `/etc/nanorc`:

```bash
set nowrap
set speller "hunspell"
set tabsize 2
set tabstospaces
include "/usr/share/nano/nanorc.nanorc"
include "/usr/share/nano/c.nanorc"
include "/usr/share/nano/css.nanorc"
include "/usr/share/nano/html.nanorc"
include "/usr/share/nano/php.nanorc"
include "/usr/share/nano/mutt.nanorc"
include "/usr/share/nano/patch.nanorc"
include "/usr/share/nano/perl.nanorc"
include "/usr/share/nano/python.nanorc"
include "/usr/share/nano/objc.nanorc"
include "/usr/share/nano/awk.nanorc"
include "/usr/share/nano/sh.nanorc"
include "/usr/share/nano/xml.nanorc"
```

> Для получения всех активных настроек из любого конфига можно воспользоваться командой:
>
```bash
$ cat /path/to/file | grep -v -e '^#' -e '^;' -e '^$'
```

В `/etc/profile` добавляем следующее:

```bash
# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\[$(tput bold)\]\[$(tput setaf 1)\][\[$(tput setaf 3)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 6)\]\h \[$(tput setaf 5)\]\w\[$(tput setaf 1)\]]\[$(tput setaf 7)\]\\$ \[$(tput sgr0)\]"

export VISUAL=nano
export EDITOR=nano
alias nano='nano -w$'
```

А в `~/.bashrc`:

```bash
# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\[$(tput bold)\]\[$(tput setaf 7)\][\[$(tput setaf 1)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 5)\]\h \[$(tput setaf 2)\]\w\[$(tput setaf 7)\]]\\$ \[$(tput sgr0)\]"
```

Опционально - изменяем текст приветствия путём правки файла `/etc/motd` и прописывая в него имя сервера, [написанное ASCII символами](http://patorjk.com/software/taag/#p=display&#038;f=Small&#038;t=HelloWorld).

### Настраиваем SSH

> По хорошему следует отключить возможность логина в систему из под рута, и настроить аутентификацию по ключу да и только

Правим конфиг демона ssh (`/etc/ssh/sshd_config`) изменяя следующие значения:

```ini
Port 16661
AddressFamily inet
Protocol 2
LoginGraceTime 60
MaxAuthTries 1
MaxSessions 3
PermitEmptyPasswords no
PasswordAuthentication yes
KerberosGetAFSToken no
GSSAPIAuthentication no
GSSAPIKeyExchange no
UsePAM no
UseDNS no
```

После чего его перезапускаем:

```bash
$ service sshd restart && exit
```

И коннектимся по-новой на новый порт (16661).

### Шаг #1 - Настраиваем дату, время, etc

Изменяем имя сервера:

```bash
$ nano /etc/hostname # прописываем server_name
$ hostname server_name
```

Выставляем часовой пояс:

```bash
$ unlink /etc/localtime
$ ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime
```

Настраиваем синхронизацию времени (ntp):

```bash
$ chkconfig ntpd on
$ ntpdate pool.ntp.org
$ nano /etc/ntp.conf
```

И добавляем в конец файла:

```bash
server 0.rhel.pool.ntp.org
server 1.rhel.pool.ntp.org
server 2.rhel.pool.ntp.org
```

Изменяем DNS-сервера на от Яндекса, вписав их первыми:

```bash
$ nano /etc/resolv.conf
```

```bash
nameserver 77.88.8.8
nameserver 77.88.8.1
```

Добавляем юзера, под которым будем работать, и сразу задаем ему пароль:

```bash
$ useradd %username%; passwd %username%

Changing password for user %username%.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
```

Создаем группу для демонов web-стека, и добавим в неё нашего пользователя:

```bash
$ groupadd www-data
$ usermod -a -G www-data %username%
```

А так же разрешим пользователю выполнять команды от имени рута (_после ввода **своего** пароля_), добавив в конец `/etc/sudoers` строку вида:

```bash
%username%   ALL=(ALL) ALL
```

Ставим "базовые" пакеты:

```bash
$ yum -y install epel-release wget unzip bzip2 openssl mc iptables-services
```

Запускаем обновление установленных пакетов:

```bash
$ yum -y update
```

И ставим эту-же процедуру в cron, запуская её раз в три дня, например:

```bash
$ crontab -e
```

```bash
MAILTO=""
# -----------------------------------------------------------------------------------------

 20     0     */3   *    * nice -n 15 yum -y update

# -     -     -     -    - ----------------------------------------------------------------
# |     |     |     |    |
# |     |     |     |    +----- day of week (0 - 6) (Sunday=0)
# |     |     |     +------- month (1 - 12)
# |     |     +--------- day of month (1 - 31)
# |     +----------- hour (0 - 23)
# +------------- min (0 - 59)
```

### Шаг #2 - nginx

Смотрим какая его версия доступна в "стандартном" репозитории:

```bash
$ yum info nginx
# ...
Name        : nginx
Arch        : x86_64
Version     : 1.6.3
Release     : 9.el7
# ...
```

Не комильфо. [Подключаем официальный](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/) репозиторий nginx:

```bash
$ nano /etc/yum.repos.d/nginx.repo
```

Вставляем:

```ini
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

Проверяем:

```bash
$ yum info nginx
# ...
Name        : nginx
Arch        : x86_64
Version     : 1.10.1
Release     : 1.el7.ngx
# ...
```

Вот так уже лучше. Ставим:

```bash
$ yum install -y nginx
```

Добавим пользователя nginx в группу демонов web-стека:

```bash
$ usermod -a -G www-data nginx
```

И сразу же правим его конфиг:

```bash
$ nano /etc/nginx/nginx.conf
```

```nginx
user nginx www-data;
pid  /var/run/nginx.pid;

worker_processes 4;
worker_rlimit_nofile 2048;

events {
  worker_connections  1024;
  multi_accept on;
}

error_log  /var/log/nginx/error.log warn;

http {
  include /etc/nginx/mime.types;

  # Core
  server_tokens off;
  chunked_transfer_encoding on;
  client_body_buffer_size 32k;
  client_max_body_size 64m;
  client_body_in_file_only off;
  large_client_header_buffers 1 8k;
  default_type application/octet-stream;
  disable_symlinks off;
  ignore_invalid_headers on;
  underscores_in_headers on;
  sendfile on;
  access_log off;
  tcp_nodelay on;
  tcp_nopush on;
  keepalive_disable msie6;
  keepalive_requests 256;
  keepalive_timeout 30;
  send_timeout 20s;
  reset_timedout_connection on;
  client_body_timeout 20;
  open_file_cache max=4096 inactive=20s;
  open_file_cache_valid 40s;
  open_file_cache_min_uses 2;
  open_file_cache_errors on;

  # GZip
  gzip on;
  gzip_buffers 16 8k;
  gzip_comp_level 5;
  gzip_min_length 10;
  gzip_http_version 1.1;
  gzip_vary on;
  gzip_proxied off;
  gzip_static on;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";
  gzip_types text/plain application/xml text/css application/x-javascript text/javascript application/javascript image/svg+xml;

  # SSL
  ssl_session_cache   shared:SSL:2m;
  ssl_session_timeout 2h;
  ssl_prefer_server_ciphers on;
  ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers kEECDH+AES128:kEECDH:kEDH:-3DES:kRSA+AES128:kEDH+3DES:DES-CBC3-SHA:!RC4:!aNULL:!eNULL:!MD5:!EXPORT:!LOW:!SEED:!CAMELLIA:!IDEA:!PSK:!SRP:!SSLv2;
  resolver 8.8.8.8;

  access_log off;
  index index.php index.html index.htm;

  upstream php {
    server unix:/var/run/php5-fpm.sock;
  }

  include /etc/nginx/conf.d/*.conf;
}
```

Настраиваем параметры fastcgi:

```bash
$ nano /etc/nginx/fastcgi_params
```

```nginx
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  REQUEST_SCHEME     $scheme;
fastcgi_param  HTTPS              $https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
fastcgi_index  index.php;

fastcgi_split_path_info ^(.+\.php)(/.+)$;
```

Правим конфиг "сайта по умолчанию", который будет открываться если постучаться по http непосредственно на IP сервера:

```bash
$ nano /etc/nginx/conf.d/default.conf
```

```nginx
server {
  listen      *:80 default_server;
  root        /var/www/www;
  access_log  /var/www/log/nginx.access.log;
  error_log   /var/www/log/nginx.error.log;

  # Uncomment line below after configuration comlete
  #return 444;

  include include/default.conf;

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass php;
  }
}
```

И создадим директории для файлов и логов под него соответственно:

```bash
$ mkdir -p /var/www/www
$ mkdir -p /var/www/log
```

Создаем директорию для шаред-конфигов (_которые будем подключать при необходимости_), и создаем основные:

```bash
$ mkdir /etc/nginx/include
$ nano /etc/nginx/include/default.conf
```

```nginx
## Setup default error pages
include include/errorpages.conf;

## Deny direct access for hidden files/directories
location ~ /\. {
  return 403;
}
```

Этот конфиг отвечает за кастомные страницы ошибок сервера (_вместо унылых стандартных_):

```bash
$ nano /etc/nginx/include/errorpages.conf
```

```nginx
error_page 400 /errorpages/400.html;
error_page 401 /errorpages/401.html;
error_page 402 /errorpages/402.html;
error_page 403 /errorpages/403.html;
error_page 404 /errorpages/404.html;
error_page 405 /errorpages/405.html;
error_page 406 /errorpages/406.html;
error_page 407 /errorpages/407.html;
error_page 408 /errorpages/408.html;
error_page 409 /errorpages/409.html;
error_page 410 /errorpages/410.html;
error_page 411 /errorpages/411.html;
error_page 412 /errorpages/412.html;
error_page 413 /errorpages/413.html;
error_page 414 /errorpages/414.html;
error_page 415 /errorpages/415.html;
error_page 416 /errorpages/416.html;
error_page 417 /errorpages/417.html;

error_page 500 /errorpages/500.html;
error_page 501 /errorpages/501.html;
error_page 502 /errorpages/502.html;
error_page 503 /errorpages/503.html;
error_page 504 /errorpages/504.html;
error_page 505 /errorpages/505.html;
error_page 511 /errorpages/511.html;

location ^~ /errorpages/ {
  internal;
  root /var/www;
}
```

Создадим директорию для кастомных страниц ошибок, и наполним её смыслом:

```bash
$ mkdir -p /var/www/errorpages && cd /var/www/errorpages
$ wget --no-check-certificate https://github.com/TheBlackParrot/error-pages/archive/master.zip
$ unzip ./master.zip
$ mv ./*/*/*.html ./ # Move all html files to this directory
$ rm -Rf -- */ # Remove all directories
$ find . -type f ! -name '*.html' -delete # Remove all files except *.html pattern
$ ls -l && cd ~
```

После чего запускаем nginx, и если всё хорошо, то ставим его в авто-запуск:

```bash
$ service nginx start && service nginx status
$ chkconfig nginx on
```

После чего пробуем в браузере обратиться к нашему серверу по IP - должны увидеть красивую ошибку 403.

### Шаг #3 - PHP 5.6 и php-fpm

Ну что-ж, приступим-с:

```bash
$ wget https://centos7.iuscommunity.org/ius-release.rpm
$ rpm -Uvh ius-release*.rpm # Add repotitory with php56
$ rm -f ius-release*.rpm
$ yum -y update
$ yum -y install php56u-common php56u-cli php56u-fpm php56u-mbstring php56u-mcrypt php56u-mysqlnd php56u-opcache php56u-pdo php56u-pear php56u-pecl-jsonc php56u-process php56u-xml php56u-gd php56u-intl php56u-bcmath
# ...
Complete!
$ yum list installed | grep php
php56u-bcmath.x86_64                 5.6.22-2.ius.centos7           @ius
php56u-cli.x86_64                    5.6.22-2.ius.centos7           @ius
php56u-common.x86_64                 5.6.22-2.ius.centos7           @ius
php56u-fpm.x86_64                    5.6.22-2.ius.centos7           @ius
php56u-gd.x86_64                     5.6.22-2.ius.centos7           @ius
php56u-intl.x86_64                   5.6.22-2.ius.centos7           @ius
php56u-mbstring.x86_64               5.6.22-2.ius.centos7           @ius
php56u-mcrypt.x86_64                 5.6.22-2.ius.centos7           @ius
php56u-mysqlnd.x86_64                5.6.22-2.ius.centos7           @ius
php56u-opcache.x86_64                5.6.22-2.ius.centos7           @ius
php56u-pdo.x86_64                    5.6.22-2.ius.centos7           @ius
php56u-pear.noarch                   1:1.10.1-4.ius.centos7         @ius
php56u-pecl-jsonc.x86_64             1.3.9-2.ius.centos7            @ius
php56u-process.x86_64                5.6.22-2.ius.centos7           @ius
php56u-xml.x86_64                    5.6.22-2.ius.centos7           @ius
```

Настраиваем php-fpm примерно так:

```bash
$ nano /etc/php-fpm.conf
```

```ini
include=/etc/php-fpm.d/*.conf
[global]
pid = /run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log
daemonize = yes
```

```bash
$ nano /etc/php-fpm.d/www.conf
```

```ini
[www]
user = php-fpm
group = www-data
listen = /var/run/php5-fpm.sock
listen.owner = php-fpm
listen.group = www-data
listen.mode = 0660
listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
slowlog = /var/log/php-fpm/www-slow.log
env[TMP] = /tmp
env[TEMP] = /tmp
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /tmp
php_value[soap.wsdl_cache_dir]  = /tmp
```

В конфиге php **меняем** следующие значения:

```bash
$ nano /etc/php.ini
```

```ini
; ...
display_errors = On
disable_functions = popen, exec, system, passthru, proc_open, shell_exec
expose_php = Off
post_max_size = 40M
upload_max_filesize = 40M
date.timezone = Europe/Moscow
session.save_path = "/tmp"
session.gc_maxlifetime = 11440
; ...
```

Добавим пользователя `php-fpm` в группу `www-data`:

```bash
$ usermod -a -G www-data php-fpm
```

После чего перезапускаем демонов и ставим php-fpm в автозапуск:

```bash
$ service nginx restart && service php-fpm restart
$ service php-fpm status
$ chkconfig php-fpm on
```

Создаем проверочный файл:

```bash
$ echo '<?php phpinfo();' > /var/www/www/test.php
```

И открываем в браузере страницу `http://%server_ip%/test.php`. Мы должны увидеть вывод команды `phpinfo()`.

### Шаг #4 - MySQL 5.7

Не будет откладывать неизбежное:

```bash
$ wget http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
$ yum localinstall mysql57-community-release-el7-7.noarch.rpm
$ yum info mysql-community-server
# ...
Name        : mysql-community-server
Version     : 5.7.13
Release     : 1.el7
Size        : 151 M
# ...
$ yum -y install mysql-community-common mysql-community-server mysql-community-client
$ service mysqld start && service mysqld status
$ chkconfig mysqld on # Enable autostart
```

Настраиваем следующим образом:

```bash
$ nano /etc/my.cnf
```

```ini
[mysqld]
innodb_buffer_pool_size = 256M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
innodb_flush_neighbors=0
innodb_flush_log_at_trx_commit=2
character-set-server=utf8
collation-server=utf8_general_ci
symbolic-links=0
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
skip-networking
skip-federated
skip-blackhole
skip-archive
skip-external-locking
```

И перезапускаем демона:

```bash
$ service mysqld restart
```

Получаем значение временного пароля для учетной записи `root`:

```bash
$ grep 'temporary password' /var/log/mysqld.log
2016-06-28T20:22:46.003656Z 1 [Note] A temporary password is generated for root@localhost: PASSWORD_HERE
```

После чего запускаем mysql_secure_installation:

```bash
$ mysql_secure_installation
# Вводим новый пароль, который должен содержать символы разного регистра, цифры и
# спец-символы, и быть длинной >12 символов
# На все остальные вопросы отвечаем положительно
```

### Шаг #5 - Настраиваем сервер исходящей почты

О том как это сделать ты можешь прочитать по [этой ссылке]({{< ref "compile-and-config-msmtp.md" >}}). Не забудь внести соответствующие изменения в `/etc/php.ini` при их наличии.

### Шаг #6 - FTP сервер

Ставим из репозитория:

```bash
$ yum install vsftpd
```

Настраиваем так, что бы демон слушал не стандартный порт, показывал скрытые файлы, не рвал сессию раньше положенного времени и позволял подключаться пользователям за исключением root-а:

```bash
$ nano /etc/vsftpd/vsftpd.conf
```

```ini
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=NO
xferlog_std_format=YES
idle_session_timeout=3600
data_connection_timeout=1800
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
listen_port=21312
pasv_min_port=21313
pasv_max_port=21350
```

Запускаем и ставим а автозапуск:

```bash
$ service vsftpd restart
$ chkconfig vsftpd on
```

После чего пытаемся присоединиться к серверу на порт 21312 под именем пользователя, созданным ранее.

### Шаг #7 - phpMyAdmin

Считаем что у нас есть доступ к редактированию DNS зоны домена для сайта, который будет располагаться на сервере, и уже имеется запись типа `А` с именем хоста `pma`, которая ведет на IP нашего сервера. Говоря проще - прописан субдомен `pma.your_domain.ru`. Нам остается сделать так, что бы по обращению к нему у нас открывался phpmyadmin.

Так как на момент написания этого поста мне не удалось найти репозитория содержащего последнюю версию phpmyadmin, мы будем ставить его из исходников. Для чего сперва создадим соответствующие директории:

```bash
$ mkdir -p /var/www/pma/www
$ mkdir -p /var/www/pma/log
```

Переходим в www и скачиваем исходники (актуальную ссылку [смотри на сайте](https://www.phpmyadmin.net/downloads/)):

```bash
$ cd /var/www/pma/www
$ wget https://files.phpmyadmin.net/phpMyAdmin/4.6.3/phpMyAdmin-4.6.3-all-languages.tar.gz
$ tar -zxvf ./phpMyAdmin-*.tar.gz && rm -f ./phpMyAdmin-*.tar.gz
```

Размещаем их в корне и удаляем пустую директорию:

```bash
$ mv ./*/* ./ && rm -Rf ./phpMyAdmin-*
```

Удаляем не нужные локализации:

```bash
$ cd locale/ && ls -l
# Ахуительный список. Удаляем все, кроме 'ru'
$ find . -maxdepth 1 -type d -not -name 'ru' -exec rm -Rf {} +
$ cd ..
```

Теперь нам необходимо запустить это добро под nginx + php-fpm. Создаем конфиг нашего субдомена:

```bash
$ nano /etc/nginx/conf.d/pma.domain_name.ru.conf
```

```nginx
server {
  listen      80;
  server_name pma.domain_name.ru;
  root        /var/www/pma/www;
  access_log  /var/www/pma/log/nginx.access.log;
  error_log   /var/www/pma/log/nginx.error.log;

  include include/default.conf;

  ## Enable client-side cache
  location ~* ^.+\.(css|js|ogv|svg|svgz|eot|otf|woff|woff2|ttf|jpg|jpeg|gif|png|ico)$ {
    access_log off;
    expires 21d;
  }

  location ~* /(build.xml|composer.json|templates|test|libraries|ChangeLog|README|LICENSE) {
    return 444;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $request_filename;
    fastcgi_read_timeout 300; # 5 minutes
    send_timeout         300; # 5 minutes
    fastcgi_pass php;
  }
}
```

Создаем конфиг phpmyadmin из его сэмпла и немного его правим:

```bash
$ cp ./config.sample.inc.php ./config.inc.php
$ nano ./config.inc.php
```

Изменяем значение `$cfg['blowfish_secret']` произвольной строкой в > 32 символов, и добавляем два значения для активации капчи при авторизации:

```php
$cfg['CaptchaLoginPrivateKey'] = 'AABBCCDD_PRIVATE_KEY_00112233';
$cfg['CaptchaLoginPublicKey'] = 'AABBCCDD_PUBLIC_KEY_00112233';
```

Сами же ключи берем по [этой ссылке](https://www.google.com/recaptcha/admin#list).

После чего говорим nginx перечитать конфиг:

```bash
$ nginx -s reload
```

И открываем страницу `http://pma.domain_name.ru/`, пытаясь войти под рутом (_очень важно **отключить возможность входа под рутом** после развертывания всех сайтов_).

### Шаг #8 - Огненная стена

По умолчанию в CentOS работает файрвол `firewalld`, не смотря на то что так же стоит старый добрый `iptables`. Отключаем `firewalld`:

```bash
$ chkconfig firewalld off
$ systemctl disable firewalld
$ systemctl mask firewalld
$ systemctl enable iptables
$ service iptables restart
```

Прописываем все наши не стандартные порты демонов в jail ACCEPT для того чтоб если мы закрылись файрволом по умолчанию, то сервисы работали бы:

```bash
$ iptables -I INPUT -p tcp --dport %SERVICE1_PORT_NUM% -j ACCEPT
$ iptables -I INPUT -p tcp --dport %SERVICE2_PORT_NUM% -j ACCEPT
# etc
$ service iptables save
```

> Заметка для себя - пора бы уже перейти на `firewall-cmd`

### Шаг #9 - memcached

Очень часто нужен, да и тот же wp с ним дружит и показывает неплохие результаты. Ставим и настраиваем:

```bash
$ yum -y install memcached php56u-memcache
$ ln -s /etc/sysconfig/memcached /etc/memcached
$ nano /etc/memcached
```

```ini
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="256"
OPTIONS=""
```

Закрываем его порт извне, ставим в автозапуск и перезапускаем демонов:

```bash
$ iptables -A INPUT ! -s 127.0.0.1/8 -p tcp --dport 11211 -j REJECT --reject-with tcp-reset
$ service iptables save && service iptables restart
$ service memcached restart
$ chkconfig memcached on
$ service php-fpm restart && service nginx restart
```

### Шаг #10 - Бэкапы

Не будем изобретать велосипед и писать свои скрипты. Воспользуемся [backup-manager](http://github.com/sukria/Backup-Manager):

```bash
$ yum -y install backup-manager
$ rm -R /var/backup-manager # вместо неё будет /var/backups
$ nano /etc/backup-manager.conf
```

```bash
# ...
export BM_REPOSITORY_ROOT="/var/backups"
export BM_TEMP_DIR="/tmp"
export BM_ARCHIVE_CHMOD="660"
export BM_ARCHIVE_TTL="15"
export BM_ARCHIVE_METHOD="tarball mysql"
BM_TARBALL_TARGETS[0]="/etc"
BM_TARBALL_TARGETS[1]="/root"
BM_TARBALL_TARGETS[2]="/home/username"
BM_TARBALL_TARGETS[3]="/var/www"
export BM_TARBALL_BLACKLIST="/dev /sys /proc /tmp /root/tmp /home/username/tmp"
export BM_MYSQL_DATABASES="__ALL__"
export BM_MYSQL_ADMINLOGIN="root"
export BM_MYSQL_ADMINPASS="mysql_root_password_here"
# ...
```

При необходимости настраивается аплоад на удаленную машину, но это уже частный случай. Ставим в крон:

```bash
$ crontab -e
```

```bash
0  */2  *  *  *  nice -n 17 /usr/sbin/backup-manager
```

Делаем тестовый запуск и обязательно проверяем содержимое архивов:

```bash
$ backup-manager
$ mc /var/backups/
```
