---
title: Установка LAMP на CentOS 7
date: 2015-01-26T08:43:00+00:00
aliases:
  - /adm/change-hosting-to-hetzner-de.html
featured_image: /images/posts/lamp-wide.jpg
tags:
  - apache
  - centos
  - ftp
  - hetzner
  - hetzner.de
  - hosting
  - httpd
  - linux
  - nginx
  - shell
  - ssh
  - vds
---

Так уж получилось, что хостер, где ранее размещались все сайты и некоторые сервисы, оказался жлоб и пидарас. Жлоб, потому как на самом дорогом тарифе выделял лишь сраные 256Mb под всё, а пидарас — потому как и с поддержкой — не очень хорошо, и хосты частенько лежали, и отношение к клиентам — далеко не лучшее. Да, речь о Nic.ru.

Было решено переезжать. Но куда? В России достойное по соотношению цена/качества — не находилось, а “за бугром”, по рекомендациям хабра — был выбран [hetzner.de][1].

<!--more-->

Сказано — сделано. Только куплен не хостинг, а виртуальный выделенный сервер, с характеристиками:

- Камень: **Intel(R) Core(TM)2 Duo CPU T7700 @ 2.40GHz**
- Кэш камня: **4096 KB**
- Память: **994.1 MB**
- Сеть: добрые **50 МБит**
- ОС: на выбор, но я ставил **CentOS Linux 7.0.1406 (x64)**

После того что было - есть где разгуляться. А самое главное - почти за те же деньги. Остается всё поставить и настроить.

Ставить мы будем вот что:

- **nginx** в качестве фронтэнда;
- **httpd** (Apache 2) + **php** в качестве бэкэнда;
- **vsftpd** - ftp сервер;
- **mariadb** (mysql) в качестве сервера БД с мордой phpMyAdmin.

Этот пост — скорее как шпаргалка для самого себя, т.к. уже успел сервер положить на лопатки, и пришлось всё делать заново (к слову — бэкап, разумеется, был; а настройки удалось выдернуть, загрузившись с рековери-образа в режиме восстановления). Но, как говорит мой товарищ “Хорош пиздеть, поехали”:

Ставим стартовый набор и обновляемся:

```bash
$ yum update; yum install nano mc
```

Правим имя хоста:

```bash
$ nano /etc/hostname
```

Изменяем DNS-сервера на российские (от Яндекса - `77.88.8.8` и `77.88.8.1`):

```bash
$ nano /etc/resolv.conf
```

Правим вид консоли, придаем ей человеческий образ, и ставим в качестве редактора по умолчанию - nano:

```bash
$ nano ~/.bashrc
```

```bash
export VISUAL=nano
export EDITOR=nano
# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="[$(tput bold)][$(tput setaf 7)][[$(tput setaf 1)]u[$(tput setaf 7)]@[$(tput setaf 5)]h [$(tput setaf 2)]w[$(tput setaf 7)]]\$ [$(tput sgr0)]"
```

Изменяем порт ssh на нетипичный, например - 23432:

```bash
$ nano /etc/ssh/sshd_config
```

```ini
Port 23432
Protocol 2
```

И перезапускаем ssh сервер (после коннектимся на новый порт):

```bash
$ service sshd restart
```

Создаем swap и монтируем его:

```bash
$ dd if=/dev/zero of=/swap bs=1M count=1024
$ mkswap /swap
$ swapon /swap
```

И чтоб swap монтировался при запуске системы (сам он этого делать не будет) добавляем `swapon /swap` в `/etc/rc.local`.

Добавляем юзера, под которым будем работать, и сразу задаем ему пароль:

```bash
$ useradd kot
$ passwd kot
```

Меняем рабочую директория (т.к. у меня всего один пользователь и планировался, то я его переместил сходу в /home/):

```bash
$ usermod -m -d /home/ kot; chown kot:kot /home/
```

Ставим FTP:

```bash
$ yum install vsftpd
```

Настраиваем:

```bash
$ nano /etc/vsftpd/vsftpd.conf
```

И (пере)запускаем:

```bash
$ service vsftpd restart
```

Примерный конфиг у меня такой:

```ini
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
listen_port=12312
xferlog_std_format=YES
idle_session_timeout=3600
data_connection_timeout=3600
listen=NO
listen_ipv6=YES
force_dot_files=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
```

Демон висит на порту 12312, соединение по таймауту с ходу не обрывает, скрытые директории и файлы - показывает.

Потом меня забесил темно-синий цвет в выводе ls - ну не видно нихера. Изменил его (на `DIR 01;36`):

```bash
$ nano /etc/DIR_COLORS
```

Продолжаем установку пакетов:

```bash
$ yum install zip unzip bzip bzip2
```

Ставим поддержку распаковки из rar-архивов (надо для одного сервиса):

```bash
$ wget http://pkgs.repoforge.org/unrar/unrar-4.0.7-1.el6.rf.x86_64.rpm
$ rpm -Uvh unrar-4.0.7-1.el6.rf.x86_64.rpm
$ rm unrar-4.0.7-1.el6.rf.x86_64.rpm
```

Ставим web-сервисы и иже с ними:

```bash
$ yum install httpd nginx mariadb-server php phpMyAdmin crontabs htop iptables-services
```

Настраиваем httpd (Apache 2):

```bash
$ nano /etc/httpd/conf/httpd.conf
```

Для апача также ставим `mod_realip2` ([по этой инструкции][2], в комментарии к посту по ссылке одно важное замечание), иначе в логах будет 127.0.0.1 вместо реального адреса пользователя. Настраиваем его на работу на **8080** порту.

Ставим так же и `mod_geoip` для определения - откуда пользователь (настройку его производите самостоятельно, и не забудьте - .dat файлы необходимы в периодическом обновлении):

```bash
$ yum install geoip geoip-devel
```

После всех настроек выполняем (пере)запуск httpd демона, материмся, анализируем причину “почему не заработало”, правим, и снова (пере)запускаем:

```bash
$ service httpd restart
```

Т.к. phpMyAdmin у нас уже стоит, он по умолчанию доступен отовсюду по ссылке %виртуалхост%/phpmyadmin. Это мы исправляем, и разрешаем лишь на “главном хосте”, для чего конфиг “главного хоста” у нас может быть таким:

```apache
<VirtualHost *:8080>
  ServerName localhost.local
  DocumentRoot /home/main.host/docs
  <Directory "/home/main.host/docs">
    AllowOverride All
    Require all granted
    Satisfy all
  </Directory>
  Alias /phpMyAdmin/ /usr/share/phpMyAdmin/
  <Directory /usr/share/phpMyAdmin/>
    AddDefaultCharset UTF-8
    Require all granted
  </Directory>
</VirtualHost>
```

А сам конфиг `%phpmyadmin%.conf` из `/etc/httpd/conf.d/` (или `/etc/httpd/conf.modules.d/`) сносим к ебеням.

Так же выполняем первоначальную настройку:

```bash
$ mysql
mysql> DROP DATABASE test;
mysql> USE mysql;
mysql> UPDATE user SET Password=PASSWORD('MyMysqlPassword') WHERE user='root';
mysql> FLUSH PRIVILEGES;
mysql> quit
```

Далее - настраиваем nginx:

```bash
$ nano /etc/nginx/nginx.conf
```

И настраиваем его на работу на **80** порту, и что можно отдавать им - отдаем им, остальное - пропускаем на апач - `proxy_pass http://127.0.0.1:8080/;`.

Далее - БД, Машка (MariaDB, она же MySQL). Правим конфиг:

```bash
$ nano /etc/my.cnf
```

И доводим его примерно до такого вида:

```ini
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
key_buffer = 16M
max_allowed_packet = 4M
table_cache = 32
sort_buffer_size = 2M
read_buffer_size = 4M
read_rnd_buffer_size = 2M
net_buffer_length = 20K
thread_stack = 640K
tmp_table_size = 16M
query_cache_limit = 1M
query_cache_size = 4M
skip-networking
skip-federated
skip-blackhole
skip-archive
skip-external-locking

[mysqldump]
quick
max_allowed_packet = 16M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d
```

Делая её работу чуть “попроще”, да и запрещая доступ к БД “извне”. И (пере)запускаем:

```bash
$ service mariadb restart
```

На данный момент у нас должно уже всё работать. Закрываем извне доступ к апачу, т.к. у нас весь трафик ходит через nginx:

```bash
$ iptables -A INPUT -i eth0 -p tcp -m tcp --dport 8080 -j DROP
$ service iptables save
```

Ещё одна тонкость - давай ограничим количество соединений по SSH до, скажем, четырех в минуту. Тем самым защитившись от перебора паролей ssh (ssh порт у нас 23432):

```bash
$ iptables -A INPUT -p tcp --dport 23432 -i eth0 -m state --state NEW -m recent --set
$ iptables -A INPUT -p tcp --dport 23432 -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
$ service iptables save
```

Так же есть смысл сразу [настроить logrotate][3].

А после всего запустить `htop`, откинуться на спинку, и сказать - “А это было совсем не сложно”.

![image][4]

Ссылки, которые могут быть так же интересны:

- [LAMP +Nginx на VPS стабильно и без лишней головной боли][5]
- [Настройка Nginx + LAMP сервера в домашних условиях][6]
- [Настраиваем свой первый VDS сервер в роли веб-сервера][7]
- [DNS-хостинг Яндекса][8]
- [Яндекс.DNS — безопасный домашний интернет][9]
- [Руководство по iptables (Iptables Tutorial 1.1.19)][10]
- [Chmod, Umask, Stat, Fileperms, and File Permissions][11]
- [eZ Server Monitor - A lightweight and simple dashboard monitor for Linux][12]

[1]:http://www.hetzner.de/
[2]:http://moonback.ru/page/apache2-realip-nginx
[3]:http://debianworld.ru/articles/rotaciya-logov-s-pomoshyu-logrotate-v-debian-ubuntu/
[4]:https://habrastorage.org/files/81f/6d9/fe4/81f6d9fe4d60492b8641d02283350a28.png
[5]:https://habr.com/post/132302/
[6]:https://habr.com/post/159203/
[7]:https://habr.com/post/160647/
[8]:https://habr.com/company/yandex/blog/104652/
[9]:https://habr.com/post/196844/
[10]:http://www.opennet.ru/docs/RUS/iptables/
[11]:http://www.askapache.com/security/chmod-stat.html
[12]:http://www.ezservermonitor.com/
