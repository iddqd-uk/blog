---
title: Настройка хостинга на RU-Center (nic.ru)
date: 2016-01-22T10:14:01+00:00
aliases:
  - /adm/config-hosting-rucenter.html
featured_image: /images/posts/rucenter-cfg-wide.jpg
tags:
  - apache
  - backup
  - bash
  - nginx
  - nic.ru
---

Так уж сложилось, что время от времени приходится поднимать сайты на хостинге руцентра. Как правило это небольшие сайты-визитки или проекты, для которых реализация на дедике характеризуется как "жирно будет".

<!--more-->

Итак, отбросим причины в сторону. Первым делом - что нам понадобится для того чтоб всё сделать "под ключ", т.е. владельцем домена/хостинга был заказчик (как физ.лицо), а ты был лишь лицом, которое выполняет работу? От заказчика тебе потребуется:

- Фотографии/сканы разворота паспорта и страницы с пропиской;
- Логин/пароль от почтового ящика, который будет фигурировать при регистрации;
- Необходимая сумма денег для оплаты требуемых услуг.

> **Вопрос**: При регистрации домена может сразу встать вопрос - делегировать домен на руцентр или, например, сразу же на [DNS-хостинге от Яндекса](https://pdd.yandex.ru/)?
>
> **Ответ**: На руцентр. Так как для делегирования на Яндекс потребуется подтвердить права на владение доменом. И проще всего это сделать с помощью проверки наличия определенного файла с кодом в корне сайта. Поэтому - смело всё делай по дефолту, потом переделегируем, если потребность такая возникнет.

Сразу скажу - если "с сайта" будут отправляться письма и при этом хостить DNS у Яндекса - возникнут проблемы с отправкой писем. [DKIM](https://ru.wikipedia.org/wiki/DomainKeys_Identified_Mail) настроить на Яндекс будет невозможно, а у руцентра он принципиально не настраиваемый. Поэтому считай это тонкостью использования руцентра в целом.

Итак, считаем что аккаунт у нас заведен, домен - зарегистрирован, хостинг - заказан. Не забудь а [Личных данных](https://www.nic.ru/manager/contract.cgi?step=contract.edit) приложить сканы/фотографии паспорта клиента для верификации личности, так правильнее будет.

### Настройка почты

Переходим "Панель управления" &rarr; "Почтовый сервер". Выбираем наш почтовый домен (_должен быть создан автоматически; в противном случае создаем его с именем основного домена_). Первым делом лезем в "Почтовые ящики" &rarr; "postmaster@your_domain.ltd", и добавляем синонимы к ящику вида `info@ admin@ webmaster@ abuse@`. Таким образом все "важные" письма будут первым делом попадать именно на этот ящик, а владелец сайта сможет написать на своих визитках "клёвый" почтовый адрес `info@your_domain.ltd` :) Так же заходим в интерфейс самого почтового ящика (_нажимаем на его адрес вверху страницы_) и настраиваем переадресацию всех входящих писем на email-адрес заказчика.

Далее "Панель управления" &rarr; "Почтовый сервер" &rarr; "Параметры", и в поле "Обработка нераспознанной почты" вводим `postmaster@your_domain.ltd`. Таким образом письма, отправленные на несуществующий ящик (_например **blabla**@your_domain.ltd_) будут уходить на `postmaster@your_domain.ltd`, а оттуда - нашему заказчику. Если же будут заведены дополнительные адреса (_например - для сотрудников нашего заказчика_) - ничего перенастраивать не придется.

### Настройка СУБД

Настройку СУБД производить в соответствии с используемой системой управления контента. Рекомендую "выключать" все привилегии для пользователя, которые ему критически не важны. В идеале ему должно хватать лишь `INSERT` `UPDATE` `SELECT` и `DELETE`. Но это лишь в идеале. Ещё раз - тут смотри сам.

Больше особо интересных моментов в настройке для хостинга нет.

### Настройка Веб-сервера

Вот тут самое пожалуй интересное. Первым делом мы осуществляем "преднастройку" в веб-интерфейсе панели управления. Если используешь CMS "WordPress", то для тебя подойдут почти все настройки что идут "по умолчанию", но не все. Для других CMS - надо смотреть более детально и отдельно.

#### Выключаем WP_CRON для WordPress

В WordPress Есть такая штука как WP_CRON, которая позволяет выполнять "отложенные" действия, такие как отложенная публикация постов, проверка наличия обновлений и прочие весьма полезные штуки. Но это довольно тяжелая задача, надо признать, и выполнять её при каждом посещении пользователя/администратора сайта - иметь лишнюю задержку. Что мы делаем чтоб ситуацию исправить? Мы выключаем WP_CRON в WordPress путем добавления строки:

```php
define('DISABLE_WP_CRON', true);
```

В `wp-config.php`, и добавляем отдельную задачу в "Панель управления" &rarr; "Веб-сервер" &rarr; "Планировщик заданий" с именем, например - "wp cron" и выполняемой командой:

```bash
/usr/local/bin/wget -O - -q "http://your_domain.ltd/wp-cron.php"
```

Теперь пользователи не будут ощущать задержку, а все задачи крона WP будут выполняться "в фоне" с заданным интервалом (_выставь "Каждые 5 минут"_).

#### Настраиваем модули

Переходим в "Управление модулями". Здесь нам необходимо выполнить предварительную настройку как веб-сервера (Apache, а точнее просто указать какие модули ему загружать), выбрать используемую версию php (не знаю почему, но я всё ещё пользуюсь версией `5.3`), и указать необходимые параметры для php, такие как кодировка (_выставляй везде UTF-8_), максимальный размер загружаемого файла, и модули php (_выставляй их в соответствии с требованиями сайта_).

Вырубай всё откровенно лишнее и неиспользуемое. После этого перезапусти веб-сервер путем нажатия на соответствующую ссылку, и ставь свою CMS. На этом шаге у тебя должно всё работать как надо. Проверь всё - отправку писем, работу всех частей как пользовательского интерфейса, так и административной части. Всё должно работать. Только после этого мы переходим к следующей части.

#### Перевод сервера в ручной режим

Это необходимо для того, чтоб выполнить более тонкую настройку, недоступную из веб-интерфейса. Для перевода работы веб-сервера в ручной режим переходи в "Панель управления" &rarr; "Веб-сервер" и в графе "Режим настройки" жми на "Ручной". После этого действия будут созданы конфиги на основе тех настроек, которые мы выполнили ранее.

Теперь цепляемся к хостингу по `ssh` (реквизиты для соединения указаны в "Панель управления" &rarr; "Помощь"), и все дальнейшие настройки будем выполнять только в нем.

#### Настройка nginx

Первым делом нам необходимо настроить:

- Отдачу статического контента с помощью nginx
- Включить его сжатие с помощью gzip
- Настроить его хранение на стороне клиента (_вместо того, чтоб каждый раз скачивать его с нашего сервера_)

Для этого выполняем в консоли:

```bash
$ cat /etc/nginx/your_domain.ltd.site.conf
```

И смотрим как у нас был настроен nginx в автоматическом режиме. Он отдавал статику, но сжатие и хранение статики на стороне клиента - отсутствует. Испраляем-с :) Копируем из этого конфига все `location`-ы (_в моем случае это были `location /`, `location ~* ^.+\.(jpg|jpeg|gif|...` и `location @fallback`_) в конфиг `~/etc/nginx/nginx.conf`, вставляя их в секцию `server {...}`. Сделать по образу и подобию не думаю что составит трудность.

Для **включения gzip-сжатия** статики необходимо в секцию `http {...}` добавить:

```nginx
  gzip_static on;
  gzip on;
  gzip_buffers 16 8k;
  gzip_comp_level 2;
  gzip_min_length 1024;
  gzip_types text/css text/plain text/json text/x-js text/javascript text/xml application/json application/x-javascript application/xml application/xml+rss application/javascript;
  gzip_disable "msie6";
  gzip_vary on;
  gzip_http_version 1.0;
```

Добавить можно в принципе в любом месте перед началом секции `server {...}`. Теперь статика будет отдаваться значительно быстрее :)

Для того чтоб она **лишний раз не загружалась с сервера**, а хранилась на стороне клиента мы немного подправил `location` который отвечает за отдачу статики, а точнее добавим в него строку `expires 30d;`, чтоб получилось примерно следующее:

```nginx
location ~* ^.+\.(jpg|jpeg|gif|swf|png|ico|mp3|css|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|dat|avi|ppt|txt|tar|mid|midi|wav|bmp|rtf|wmv|mpeg|mpg|mp4|m4a|spx|ogx|ogv|oga|webm|weba|ogg|tbz|js|7z)$ {
    expires 30d;
    root   /home/domain-tld/your_domain.ltd/docs;
    access_log  /var/log/your_domain.ltd.access_log  combined;
    error_page 404 = @fallback;
    log_not_found off;
    accel_htaccess_switch on;
  }
```

Так же приведу для сравнения полный листинг получившегося у меня конфига:

```nginx
worker_processes  2;
error_log  /dev/null;
pid        /var/run/nginx.pid;
events {
    worker_connections  2048;
}
http {
  set_real_ip_from 10.1.0.0/16;      # MSK
  set_real_ip_from 10.3.0.0/16;      # MSK
  set_real_ip_from 195.208.0.0/23;   # MSK
  set_real_ip_from 212.192.194.0/24; # NSK
  set_real_ip_from 10.12.0.0/16;     # NSK
  set_real_ip_from 212.192.193.0/24; # NSK
  set_real_ip_from 10.15.0.0/16;     # AMS
  set_real_ip_from 178.210.94.0/24;  # AMS
  real_ip_header X-Real-IP;

  gzip_static on;
  gzip on;
  gzip_buffers 16 8k;
  gzip_comp_level 2;
  gzip_min_length 1024;
  gzip_types text/css text/plain text/json text/x-js text/javascript text/xml application/json application/x-javascript application/xml application/xml+rss application/javascript;
  gzip_disable "msie6";
  gzip_vary on;
  gzip_http_version 1.0;

  include       /usr/local/etc/nginx/mime.types;
  default_type  application/octet-stream;
  server_names_hash_bucket_size 128;
  access_log      off;
  sendfile        on;
  keepalive_timeout  65;

  #include /etc/nginx/virts_list;
  server {
    listen       10.3.138.12:80;
    server_name  your_domain.ltd your_domain.nichost.ru www.your_domain.ltd your_domain.nichost.ru;
    location / {
      proxy_pass         http://10.3.138.12:8080;
      proxy_redirect     http://your_domain.ltd:8080/ /;
      proxy_redirect     http://your_domain.nichost.ru:8080/ /;
      proxy_redirect     http://www.your_domain.ltd:8080/ /;
      proxy_redirect     http://www.your_domain.nichost.ru:8080/ /;
      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
      client_max_body_size       192m;
      client_body_buffer_size    128k;
      proxy_connect_timeout      90;
      proxy_send_timeout         900;
      proxy_read_timeout         900;
      proxy_buffer_size          64k;
      proxy_buffers              8 32k;
      proxy_busy_buffers_size    64k;
      proxy_temp_file_write_size 64k;
    }
    include /home/your_domain/etc/nginx/secure_wordpress.inc;

    # Set error pages
    set $errordocs /home/your_domain/your_domain.ltd/errordocs;
    error_page 400 /400.html; location = /400.html {root $errordocs;}
    error_page 401 /401.html; location = /401.html {root $errordocs;}
    error_page 403 /403.html; location = /403.html {root $errordocs;}
    error_page 404 /404.html; location = /404.html {root $errordocs;}
    error_page 408 /408.html; location = /408.html {root $errordocs;}
    error_page 500 /500.html; location = /500.html {root $errordocs;}
    error_page 501 /501.html; location = /501.html {root $errordocs;}
    error_page 502 /502.html; location = /502.html {root $errordocs;}
    error_page 503 /503.html; location = /503.html {root $errordocs;}
    error_page 504 /504.html; location = /504.html {root $errordocs;}

    # Static files location
    location ~*
  ^.+\.(jpg|jpeg|gif|swf|png|ico|mp3|css|zip|tgz|gz|rar|bz2|doc|xls|exe|pdf|dat|avi|ppt|txt|tar|mid|midi|wav|bmp|rtf|wmv|mpeg|mpg|mp4|m4a|spx|ogx|ogv|oga|webm|weba|ogg|tbz|js|7z)$ {
      expires 30d;
      root   /home/your_domain/your_domain.ltd/docs;
      access_log  /var/log/your_domain.ltd.access_log  combined;
      # original nic.ru line below:
      #error_page 404 = @fallback;
      log_not_found off;
      accel_htaccess_switch on;
    }
    location @fallback {
      proxy_pass http://10.3.138.12:8080;
      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
      client_max_body_size       192m;
      client_body_buffer_size    128k;
      proxy_connect_timeout      90;
      proxy_send_timeout         900;
      proxy_read_timeout         900;
      proxy_buffer_size          64k;
      proxy_buffers              8 32k;
      proxy_busy_buffers_size    64k;
      proxy_temp_file_write_size 64k;
    }
  }
}
```

Содержимое файла "~/etc/nginx/secure_wordpress.inc":

```nginx
if ($http_user_agent ~* ((perl|php|python|wpscan)|^(|-|_)$)) {return 403;}
if ($http_user_agent ~* (nmap|nikto|wikto|sf|sqlmap|bsqlbf|w3af|acunetix|havij|appscan|nic.ru|monitoring|semalt|virusdie|indy)) {return 444;}
if ($http_referer ~* (semalt.com|virusdie|mskshops.ru|apishops.ru)) {return 444;}
location ~* /(magmi.(php|ini)|uploadTester.asp|.*server.ca.pem|(x|humans).txt|(flashgallery|thumb_editor|html|phpinfo|xxx|bad).php|filezilla.xml)$ {return 444;}
if ($query_string ~* "^(.*)(/(.*my.cnf|self/environ|etc/passwd)|cmd=|curl+|bad.php)(.*)$") {return 444;}
location ~* .*/(fckeditor|kcfinder|ckfinder)/.*\.(php|asp(|x))$ {return 444;}
location ~ /\.ht {return 444;}

add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block;";

location ~* /((wp-config|plugin_upload|xmlrpc|wp-xmlrpc).php|(readme|license|changelog).(html|txt|md)|(debug|access|error)(.|_)log)$ {access_log off; log_not_found off;
return 404;}
location ~* /((dl-skin|nyemnyem|searchreplacedb2|wp-content|bogel|myluph|parser|routing).php|local.xml)$ {access_log off; log_not_found off; return 404;}
location ~* /.*((|.|%23)(wp-config|xmlrpc).*(php(_bak|~|#|%23)|txt|old|bak|save|orig(|inal)|swp|swo)).*$ {access_log off; log_not_found off; return 404;}
if ($query_string ~* "^(.*)(wp-config.php|dl-skin.php|xmlrpc.php|uploadify.php|admin-ajax.php|local.xml)(.*)$") {return 404;}
if ($query_string ~* "(concat.*\(|union.*select.*\(|union.*all.*select)") {return 404;}

if ($query_string ~* "author=[0-9]") {return 301 $scheme://$host/;}

location ~* /(?:uploads|files)/.*\.(php|cgi|py|pl)$ {return 404;}
location ~* /(wp|page)/.*wp-.*/.*$ {access_log off; log_not_found off; return 404;}

location = /wp-content/ {return 404;}            location = /wp-content {return 404;}
location = /wp-includes/ {return 404;}           location = /wp-includes {return 404;}
location = /wp-content/plugins/ {return 404;}    location = /wp-content/plugins {return 404;}
location = /wp-content/mu-plugins/ {return 404;} location = /wp-content/mu-plugins {return 404;}
location = /wp-content/uploads/ {return 404;}    location = /wp-content/uploads {return 404;}
location = /wp-content/themes/ {return 404;}     location = /wp-content/themes {return 404;}
location = /wp-content/languages/ {return 404;}         location = /wp-content/languages {return 404;}
location = /wp-content/languages/plugins/ {return 404;} location = /wp-content/languages/plugins {return 404;}
location = /wp-content/languages/themes/ {return 404;}  location = /wp-content/languages/themes {return 404;}
location ~ /wp-content/languages/(.+)\.(po|mo)$ {return 404;}
```

Теперь перезапускаем nginx и проверяем чтоб всё работало как надо с помощью, например, [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/):

```bash
$ /etc/rc.d/nginx restart
```

#### Настройка apache

Конфиг Apache теперь храниться по пути `~/etc/apache_2.4/httpd.conf`, и для его перезапуска необходимо будет выполнить команду:

```bash
$ /etc/rc.d/httpd restart
```

Всё что нам необходимо сделать здесь - это добавить 2 строки перед секцией `<VirtualHost *:8080>`: `ServerTokens Prod` и `ServerSignature Off`, которые запрещают вывод сигнатур сервера. Если тебе потребуется ещё что-то настраивать у Apache - то делай это в этом файле.

#### Настройка php

Для того, чтоб веб-сервер Apache начал читать именно наш конфиг, а не тот что лежит в директории `~/etc/` - нам необходимо скопировать соответствующий в домашнюю директорию. Поясню - например, мы используем `php` версии `5.3`. Смотрим в `~/etc/`:

```bash
$ ls -l ~/etc/php*
lrwxr-xr-x  1 root  wheel    22 Jan 18 16:55 /home/your_domain/etc/php -> ../../../usr/opt/php53
lrwxr-xr-x  1 root  wheel     9 Jan 18 16:55 /home/your_domain/etc/php.ini -> php53.ini
-rw-r--r--  1 root  wheel  1106 Jan 18 16:59 /home/your_domain/etc/php53.ini
-rw-r--r--  1 root  wheel  1156 Jan 18 08:26 /home/your_domain/etc/php56.ini
```

Конфиг есть, но писать в него мы соответственно не можем. Копируем его в домашнюю директорию под именем `php.ini`:

```bash
$ cp ~/etc/php53.ini ~/php.ini
```

И добавляем в него строку `expose_php=Off`, которая скроет версию используемого `php` и заголовках ответов веб-сервера. Перезапускаем Apache:

```bash
$ /etc/rc.d/httpd restart
```

И проверяем чтоб всё работало, но ничего лишнего наружу "не светилось".

#### Настраиваем резервное копирование

Хоть администраторы хостинга и выполняют резервное копирование - но лишней копия всё же не будет. Хранить мы будем бэкапы 31 день (_все настройки указываются в начале скрипта_), не забудь указать настройки ID хостинга (_т.е. названия твоей домашней директории_) и реквизиты для подключения к mysql базе примерно в 84 строке скрипта (_+ там же проверка на наличие итогового бэкапа бд_):

```bash
#!/bin/bash
## @author    Paramtamtam
## @project   Nic.ru backup script
## @copyright 2014 <https: //github.com/tarampampam>
## @github    https://github.com/tarampampam/nic.ru-bascup-script/
## @version   0.1.3
##
## @depends   mysqldump, tar

# *****************************************************************************
# ***                               Config                                   **
# *****************************************************************************

## nic.ru hosting id, look in 'cd ~ && pwd', ex.:
## [%YourID%@web2006 ~]$ cd ~ && pwd
## /home/%YourID%
HostingID="your_domain";
## Path to home dir, not need in change
PathToHomeDir=/home/$HostingID
## Path to directory, where backups will stored
PathToBackupsDir=$PathToHomeDir/backups
## Path to directory, where store DataBase dumps (add to backup file, and
##   remove from file system), not need in change
PathToDatabaseDumps=$PathToHomeDir/database-backup
##
## !!! IMPORTANT !!!
## Add your login, password and db_name to 'mysqldump' (line ~84)
## !!! IMPORTANT !!!
##
## Days count for backup files store, not need in change
StoreBackupsDaysCount=31

# *****************************************************************************
# ***                            END Config                                  **
# *****************************************************************************

## Found here - http://goo.gl/4Oi5ZK
cRed='e[1;31m'; cGreen='e[0;32m'; cNone='e[0m'; cYel='e[1;33m';
cBlue='e[1;34m'; cGray='e[1;30m'; cWhite='e[1;37m';

## Helpers Functions ###############################################

logmessage() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = message to output

  flag=''; outtext='';
  if [ "$1" == "-n" ]; then
    flag="-n "; outtext=$2;
  else
    outtext=$1;
  fi

  echo -e $flag[$(date +%H:%M:%S)] "$outtext";
}

## Begin work ####################################################

# Create directory for backups (if not exists)
if [ ! -d $PathToBackupsDir ]; then
  logmessage -n "Create $PathToBackupsDir.. ";
  mkdir -p $PathToBackupsDir;
  if [ -d $PathToBackupsDir ]; then
    echo -e "Ok";
  else
    echo -e "Error";
    exit 1;
  fi
fi

# Clean temp dumps $PathToDatabaseDumps + create it (ex: broken last run)
logmessage -n "Clean and prepare $PathToDatabaseDumps.. ";
rm -R -f $PathToDatabaseDumps;
mkdir -p $PathToDatabaseDumps;
if [ -d $PathToBackupsDir ]; then
  echo -e "Ok";
else
  echo -e "Error";
fi

logmessage -n "Backup DataBase(s) to $PathToDatabaseDumps.. "
mysqldump --force --opt --add-locks --user=your_domain_mysql -pXXXXXXX --databases your_domain_db > $PathToDatabaseDumps/your_domain_db.sql
# Write here all files to check exists
if [ -f $PathToDatabaseDumps/your_domain_db.sql ]; then
  echo -e "Complete";
else
  echo -e "Error";
fi


cd $PathToBackupsDir
thisBackupFileName=backup-$(date +%y-%m-%d--%H-%M)-$HostingID.tar.bz2

logmessage -n "Pack files to $PathToBackupsDir/$thisBackupFileName.. "
tar -cpPjf $PathToBackupsDir/$thisBackupFileName \
    --exclude=$PathToBackupsDir* \
    --exclude=$PathToHomeDir/tmp/* \
    --exclude=*httpd.core \
    $PathToHomeDir;
echo -e "Complete";

# Make some clean
logmessage -n "Make some clean.. ";
rm -R -f $PathToDatabaseDumps;
echo -e "Complete";

sleep 2;

## Finish work ####################################################

logmessage -n "Deleting old backups from $PathToBackupsDir.. "
find $PathToBackupsDir -type f -mtime +$StoreBackupsDaysCount -exec rm '{}' \;
for FILE in $(find $PathToBackupsDir -mtime +$StoreBackupsDaysCount -type f); do
  logmessage "Delete $FILE as Old";
  rm -f $FILE;
done;
echo -e "Complete";
```

По итогу его выполнения у нас должна появиться директория `~/backups` с текущим бэкапом всех данных. Для автоматизации в "Планировщик заданий" добавь задание вида `/home/your_domain/scripts/backup.sh` с запуском 1 раз в полночь, например.
