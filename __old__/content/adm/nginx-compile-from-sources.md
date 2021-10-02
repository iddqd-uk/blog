---
title: Собираем nginx из исходников
date: 2015-02-22T07:41:00+00:00
aliases:
  - /adm/nginx-compile-from-sources.html
featured_image: /images/posts/nginx-wide.jpg
tags:
  - bash
  - centos
  - gcc
  - linux
  - nginx
  - service
  - source
---

Постепенно переводя часть ресурсов с Apache на **nginx** возникла необходимость вывода листинга файлов (`autoindex on`, аналог `Options +Indexes` у Apache), но с возможностью некоторой его настройки (как минимум, это использование аналогов Apache `HeaderName` и `ReadmeName`).

В nginx этим занимается отдельный модуль под именем `fancyindex`, для запуска которого необходимо пересобрать весь nginx из исходников, добавив его в момент сборки.

<!--more-->

Что бы не возникло проблем с текущими настройками и зависимостями, мы будем собирать точно такую-же версию, что у нас сейчас стоит. Получаем информацию об установленной версии и параметрах её сборки:

```bash
$ nginx -V
nginx version: nginx/1.6.2
built by gcc 4.8.2 20140120 (Red Hat 4.8.2-16) (GCC)
...
```

> Можно смело обновляться на более свежую версию или ставить nginx "на чистую" по данной инструкции - проверено на версиях 1.6.2 и 1.9.1 (CentOS 7)

Идем в домашний каталог (работаем под рутом) и скачиваем исходники:

```bash
$ cd ~; mkdir ./nginx_src; cd ./nginx_src
$ wget http://www.nginx.org/download/nginx-1.6.2.tar.gz
$ tar -xvf nginx-1.6.2.tar.gz
$ cd nginx-1.6.2
```

Скачиваем модуль `fancyindex` и размещаем его исходники в `~/nginx_src/nginx-1.6.2/fancyindex/`:

```bash
$ mkdir ./fancyindex; cd ./fancyindex/
$ wget https://github.com/aperezdc/ngx-fancyindex/archive/master.zip
$ unzip master.zip
$ mv ./ngx-fancyindex-master/* ./
$ rm -Rf ./ngx-fancyindex-master/; rm -f ./master.zip
$ cd ..
```

После этого создаем файл `conf.sh`, который у нас будет конфигурять сборку:

```bash
$ touch ./conf.sh; chmod +x ./conf.sh
```

А в самом файле указываем все флаги, что были нам показаны при выводе `nginx -V`. У меня на CentOS 7 получилось следующее:

```bash
#!/bin/sh

./configure\
  --add-module=./fancyindex\
  --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic'\
  --prefix=/usr/share/nginx\
  --sbin-path=/usr/sbin/nginx\
  --conf-path=/etc/nginx/nginx.conf\
  --error-log-path=/var/log/nginx/error.log\
  --http-log-path=/var/log/nginx/access.log\
  --http-client-body-temp-path=/var/lib/nginx/tmp/client_body\
  --http-proxy-temp-path=/var/lib/nginx/tmp/proxy\
  --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi\
  --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi\
  --http-scgi-temp-path=/var/lib/nginx/tmp/scgi\
  --pid-path=/run/nginx.pid\
  --lock-path=/run/lock/subsys/nginx\
  --user=nginx\
  --group=nginx\
  --with-file-aio\
  --with-ipv6\
  --with-http_ssl_module\
  --with-http_spdy_module\
  --with-http_realip_module\
  --with-http_geoip_module\
  --with-http_mp4_module\
  --with-http_gunzip_module\
  --with-http_gzip_static_module\
  --with-pcre\
  --with-debug\
  --without-http_ssi_module\
  --without-http_autoindex_module\
  --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E'
#  --with-http_stub_status_module\
#  --with-http_image_filter_module\
#  --with-google_perftools_module\
#  --with-http_perl_module\
#  --with-http_random_index_module\
#  --with-http_secure_link_module\
#  --with-http_degradation_module\
#  --with-http_sub_module\
#  --with-http_dav_module\
#  --with-http_flv_module\
#  --with-http_addition_module\
#  --with-http_xslt_module\
#  --with-mail\
#  --with-mail_ssl_module\
```

Некоторые опции, такие как `--with-mail` осознанно отключил, т.к. этот функционал мной не используется. Теперь пытаемся запустить:

```bash
$ ./conf.sh
```

После чего смотрим вывод и гуглим причину, по которой у нас не собирается (наверняка не хватает какой-то зависимости). Мне потребовалось поставить (**перед** / **во время** сборки):

```bash
$ yum install gcc gcc-c++ pcre-devel zlib-devel make openssl-devel
$ yum install rpm-build gd-devel libxslt-devel perl-ExtUtils-Embed gperftools-devel
```

Для Debian систем список пакетов вероятнее всего будет таким:

```bash
$ apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev libbz2-dev libssl-dev tar unzip
```

> Небольшое отступление - в целях безопасности есть смысл скрыть настоящую сигнатуру используемого сервера. При помощи двух следующих шагов мы [заменим стандартный баннер nginx-а](http://stackoverflow.com/a/246294), отсылаемый при каждом запросе, и немного изменим вывод на стандартных страницах ошибок, по которым так же происходит определение используемого ПО на сервере.

Изменяем стандартный баннер ответа сервера (поправь строки 48 и 49):

```bash
$ nano ./src/http/ngx_http_header_filter_module.c
```

```с
static char ngx_http_server_string[] = "Server: SuperSecretServer" CRLF;
static char ngx_http_server_full_string[] = "Server: SuperSecretServer" CRLF;
```

И правим вывод на стандартных страницах ошибок (начиная со строки 21 и далее по тексту):

```bash
$ nano ./src/http/ngx_http_special_response.c
```

```c
static u_char ngx_http_error_full_tail[] =
"<hr><center>" /*NGINX_VER*/ "</center>" CRLF
"</body>" CRLF
"</html>" CRLF
;

static u_char ngx_http_error_tail[] =
"<hr><center>SuperSecretServer</center>" CRLF
"</body>" CRLF
"</html>" CRLF
;
...
```

И наконец таки компилируем, делаем копию конфигов и ставим:

> Не забудь - если ты пересобираешь его не первый раз, перед `$ make` выполни `$ make clean` и заново запусти `$ ./conf.sh`

```bash
$ cp -r /etc/nginx/ ~/nginx_conf
$ make
```

##### Удали старый nginx!

Если nginx у тебя был установлен из репозитория, то именно сейчас настал момент, когда требуется остановить работающий nginx и удалить его. Для этого выполни:

```bash
$ service nginx stop
$ yum erase nginx
```

Далее:

```bash
$ service nginx stop
$ make install
```

Теперь требуется создать [init-скрипт](https://gist.githubusercontent.com/tarampampam/3d165f928f2de4ed6626/raw/cbe55cb69f1af4d686a848957fe7b188e7d4b329/nginx.sh) для nginx ([источник](http://wiki.nginx.org/RedHatNginxInitScript), для чего выполним следующие команды:

> Приведенный ниже скрипт актуален для ОС семейства RedHat, для других ОС есть смысл поискать или написать свой init скрипт

```bash
$ wget -O /etc/init.d/nginx https://goo.gl/LDrMbr
$ chmod +x /etc/init.d/nginx
```

И проверим:

```bash
$ service nginx status
nginx.service - SYSV: Nginx is an HTTP(S) server, HTTP(S) reverse proxy and IMAP/POP3 proxy server
   Loaded: loaded (/etc/rc.d/init.d/nginx)
   Active: inactive (dead) since Tue 2015-06-16 13:20:07 MSK; 1s ago
  Process: 5151 ExecStop=/etc/rc.d/init.d/nginx stop (code=exited, status=0/SUCCESS)
  Process: 4759 ExecStart=/etc/rc.d/init.d/nginx start (code=exited, status=0/SUCCESS)
 Main PID: 4927 (code=exited, status=0/SUCCESS)
```

Теперь копируем конфиги обратно, запускаем, и ставим его в автозапуск при старте системы:

```bash
$ cp -r ~/nginx_conf/ /etc/nginx/
$ service nginx start
$ /sbin/chkconfig nginx on
```

После этого проверяем работоспособность нашего свежесобранного сервера и удаляем резервные копии конфигов :)
