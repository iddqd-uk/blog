---
title: Тотальная защита WordPress
date: 2015-07-05T11:30:59+00:00
aliases:
  - /wp/total-wordpress-secutity.html
aliases:
  - /adm/total-wordpress-secutity
featured_image: /images/posts/wp-secure-total-wide.jpg
tags:
  - centos
  - fail2ban
  - nginx
  - security
  - wordpress
  - wpscan
---

В [прошлом посте][make-wp-more-secure-with-nginx] мы рассматривали методы повышения безопасности WordPress с помощью `nginx`. В данной же записи мы рассмотрим дополнительные меры противодействия сбору информации о работающей CMS (_и плагинах_), версии WP и некоторым типам атак на сайт.

Помогать нам будет уже не только `nginx` - но и `fail2ban` вкупе с некоторыми дополнениями и настройками самого WP.

<!--more-->

Обозначим проблемы безопасности, которые "по умолчанию" имеют место быть:

  1. WordPress вставляет данные о своей версии в различные места генерируемого контента;
  2. Стандартные настройки его имеют довольно много потенциально слабых мест;
  3. Стандартные настройки доступа к сайту позволяют без особых трудностей собрать потенциальному взломщику довольно много информации;
  4. "Из коробки" отсутствуют какие-либо средства против перебора директорий и паролей.

Ниже мы примем требуемые меры к их решению. Данная запись будет со временем обновляться и дополняться.

## Скрываем версию

Для решения данной задачи можно воспользоваться [данным плагином][remove-wp-version]. Для его установки переходим в директорию с плагинами WordPress и скачиваем его:

```bash
$ cd /var/www/sitename.org/docs/wp-content/plugins/
$ wget -O remove-wp-version.php https://goo.gl/J3Ttq8
```

После чего переходим в панель управления плагинами и активируем его.

Плагин удаляет теги `<meta generator="..." />` и подстроку `?ver=%версия%` из запросов к css и js файлам. Никаких настроек не имеет.

## Настраиваем WP

Для внесения необходимых изменений в настройку WordPress (_и опционально его бэкэнда_) ранее был написан отдельный пост, с которым можно ознакомиться перейдя по [этой ссылке][make-wp-more-secure-part1].

В нем попунктно рассматриваются потенциально слабые места и описаны средства их устранения.

## Настраиваем nginx

Считаем что в качестве фронтенда у нас работает nginx, и несколько пересмотрев его конфиг из [прошлой записи][make-wp-more-secure-with-nginx] решил довести его до вида, который описан ниже.

Запрещаем вывод листинга файлов, если nginx собран с модулем `ngx_http_autoindex_module`:

```nginx
# Раскоментировать если nginx собран с модулем "ngx_http_autoindex_module"
autoindex off;
```

Закрываем доступ к ридмишкам, некоторым типам логов и системных файлов:

```nginx
# Запрещаем доступ ко всем ULR-ам, которые ЗАКАНЧИВАЮТСЯ следующими вхождениями
location ~* /((wp-config|plugin_upload|xmlrpc).php|(readme|license|changelog).(html|txt|md)|(debug|access|error)(.|_)log)$ {
  return 444;
}
```

> Стоит обратить внимание, что мы закрываем доступ к `xmlrpc.php` (часто используемого для DDoS сайта), после чего приложения-клиенты для WP наверняка перестанут работать

Запрещаем запросы, которые **содержат** следующие вхождения:

```nginx
# Запрещаем доступ ко всем URL, которые СОДЕРЖАТ следующие вхождения
location ~* /.*((wp-config|xmlrpc).*(php(_bak|~|#)|txt|old|bak|save|orig(|inal)|swp|swo)).*$ {
  return 444;
}
```

Запрещаем запросы, в **параметрах** которых есть следующие подстроки:

```nginx
# Запрещаем все URL-ы, в параметрах (..?a=evil) которых есть следующие вхождения
if ($query_string ~* "^(.*)(wp-config.php|dl-skin.php|xmlrpc.php|uploadify.php|admin-ajax.php|local.xml)(.*)$") {
  return 444;
}

# Для противодействия SQL-инъекциям <https://habr.com/company/xakep/blog/259843/>
if ($query_string ~* "(concat.*\(|union.*select.*\(|union.*all.*select)") {
  return 444;
}
```

Запрещаем вывод информации об авторах (и получение списка логинов через перебор `ID`) через запросы вида `?author=%ID%`:

```nginx
# Запрещаем вывод информации об авторах
if ($query_string ~* "author=[0-9]") {return 301 $scheme://$host/;}
```

Запрещаем запуск скриптов из директорий загрузок и `files`:

```nginx
# Запрет для загруженных скриптов
location ~* /(?:uploads|files)/.*\.(php|cgi|py|pl)$ {return 444;}
```

Запрещаем ссылки вида `//blog.ru/wp/wp-content/..` и `//blog.ru/page/wp-content/..`, которые часто встречаются в инструментах перебора:

```nginx
# Запрещаем ссылки вида //blog.ru/wp/wp-content/.. и //blog.ru/page/wp-content/..
location ~* /(wp|page)/.*wp-.*/.*$ {return 444;}
```

Для аудита сайтов на WordPress очень распространен такой инструмент как [WPScan](http://wpscan.org/) и на противодействии ему остановимся чуть подробнее. Даже после того, как мы приняли необходимые меры по скрытию версии WP - данный инструмент безошибочно определяет её путем получения некоторых публичных файлов и сравнения их контрольных сумм.

Крайняя версия WPScan (_на момент написания данной записи `2.8` от `2015-06-22`_) ориентирована на два файла - `/wp-includes/css/buttons-rtl.css` и `/wp-includes/js/tinymce/wp-tinymce.js.gz`. Он формирует с виду очень "правильный" запрос, с рефералом и необходимыми плюшками, всё как полагается. Если просто закрыть доступ к этим файлам то пострадает функционал WP, так как они необходимы в ряде случаев для корректной работы панели администратора. Как же решить эту задачку?

WPScan отправляет реферер, всегда равный `%scheme%://%sitename%/`. Но файлы то нам нужны только для панели администрирования, и соответственно в при их "легальном" запросе в реферере должна присутствовать подстрока `/wp-admin`. Если её нет - значит запрос можно детектировать как пришедший "извне". Этой то особенностью мы и воспользуемся :)

Более того, для понижения информативности вывода данного инструмента мы запретим ему читать файл `robots.txt`. Как запретить доступ для WPScan? Дело всё в том же реферале. Поисковые роботы не отправляют никакого реферера для его чтения, а WPScan шлёт всё тот же `%scheme%://%sitename%/` :)

```nginx
# Активно препятствуем fingerprinting-у утилиты WPScan (http://wpscan.org/)
location = /wp-includes/css/buttons-rtl.css {
  if ($http_referer !~* "/wp-admin") {return 404;}
}

location = /wp-includes/js/tinymce/wp-tinymce.js.gz {
  if ($http_referer !~* "/wp-admin") {return 404;}
}

# И так же для WPScan (который запрашивая robots.txt посылает referer сайта, хотя его быть не
# должно) закрываем доступ к этому самому robots.txt, делая вывод тулзы ещё менее информативный
location = /robots.txt {if ($http_referer != "") {return 404;}}
```

Хардкорно имитируем ошибки 404 при запросе директорий, характерных для WP:

```nginx
# Закрываем доступ к корню следующих директорий
location = /wp-content/ {return 404;}
location = /wp-includes/ {return 404;}
location = /wp-content/plugins/ {return 404;}
location = /wp-content/uploads/ {return 404;}
location = /wp-content/themes/ {return 404;}
location = /wp-content/languages/ {return 404;}
location = /wp-content/languages/plugins/ {return 404;}
location = /wp-content/languages/themes/ {return 404;}
```

И ещё один интересный момент - запрещаем прямой доступ к директориям плагинов. Делается это в первую очередь для предотвращения их раскрытия путем простого перебора имен директорий:

```nginx
# Закрываем прямой доступ у содержимому корневых директорий плагинов (для предотвращения
# их ракрытия)
location ~* /wp-content/plugins/([0-9a-z\-_]+)(/|$) {return 404;}
```

Закрываем доступ к файлам переводов (которые зачастую так же содержат версию используемой CMS):

```nginx
# Закрываем доступ к файлам перевода (для невозможности раскрыть версию WP)
location ~ /wp-content/languages/(.+)\.(po|mo)$ {return 404;}
```

Запрещаем доступ следующим `User-Agent`-ам:

```nginx
# https://habr.com/post/168739/
if ($http_user_agent ~* (nmap|nikto|wikto|sf|sqlmap|bsqlbf|w3af|acunetix|havij|appscan|nic.ru|monitoring|semalt|virusdie|indy|perl|php|python|wpscan)) {return 403;}
```

И блокируем всех, у кого `User-Agent` пустой (_или почти пустой_):

```nginx
# Блокируем конкретные юзер-агенты, в частности - пустой и "-"
if ($http_user_agent ~ ^(|-|_)$) {return 403;}
```

> Все описанные выше настройки я бы рекомендовал описать в одном файле (`secure_wordpress.inc`), и подключать в конфигурации каждой секции `server { ... }` с помощью `include secure_wordpress.inc;` где установлен WordPress.

## Настраиваем fail2ban

Для установки `fail2ban` на CentOS 7 необходимо подключить репозиторий EPEL:

```bash
$ yum install epel-release
```

Поставить сам `fail2ban` и поставить его в автозапуск:

```bash
$ yum install fail2ban
$ fail2ban-server -V
Fail2Ban v0.9.2

Copyright 2004-2008 Cyril Jaquier, 2008- Fail2Ban Contributors
Copyright of modifications held by their respective authors.
Licensed under the GNU General Public License v2 GPL.

Written by Cyril Jaquier <cyril.jaquier@fail2ban.org>.
Many contributions by Yaroslav O. Halchenko <debian@onerussian.com>.
$ chkconfig fail2ban on
```

После чего открыть файл `/etc/fail2ban/fail.local` (_если его нет, то скопировать `fail.conf`_) и добавить в него секции, описанные ниже. Давай сперва чуть подробнее разберем их предназначение и настройки.

Первая (_под именем `nginx-404`_) занимается тем, что мониторит запросы к нашему серверу которые завершились кодами `403`, `404` или `444` (_т.е. файл не был найден или в доступе к нему `nginx` отказал_) и отправляет пользователя в бан на `90` секунд, если в течение `10` секунд таких ответов было `25` штук. Данная мера необходима для того, чтоб предотвратить (_довольно сильно усложнить_) перебор наличия файлов и директорий на сервере.

> **ВНИМАНИЕ!**
>
> С указанными параметрами надо быть очень осторожным! Так как если, например, пользователь перейдет на страницу, на которой будут размещены изображения размещающиеся на самом сайте, но по какой-либо причине они **не будут доступны** (_перемещены, удалены_) в установленном количестве - пользователь будет **забанен**. Или же если будет какой-либо JS скрипт который, например, в цикле будет запрашивать несуществующий ресурс на сайте, пользователь так же будет **забанен**. Укажите те настройки, которые будут безопасны для "легальных" посетителей в первую очередь!

Вторая отвечает за ограничение попыток авторизации (_защита от брутфорса_). Если кто либо в течение `20` секунд будет пользователь произведет `10` попыток войти (отправит `POST` запрос к `/wp-login.php`) - он будет оправлен в бан на `1200` секунд.

> Как дополнительная мера - поставить плагин [Google Captcha (reCAPTCHA)](https://wordpress.org/plugins/google-captcha/), который добавит на страницу авторизации ещё и капчу.

```ini
[nginx-404]
enabled  = true
port     = http,https
filter   = nginx-404
action   = iptables-multiport[name="nginx_404", port="http,https"]
maxretry = 25
findtime = 10
bantime  = 90
logpath  = /var/www/*/log/*access*.log
           /var/www/*/log/*error*.log

[wp-auth]
enabled  = true
port     = http,https
filter   = wp-auth
action   = iptables-multiport[name="wp_auth", port="http,https"]
maxretry = 10
findtime = 20
bantime  = 1200
logpath  = /var/www/*/log/*access*.log
           /var/www/*/log/*error*.log
```

> Не забудь поправить пути к логам твоего сервера

А так же создать файлы `/etc/fail2ban/filter.d/nginx-404.conf`:

```ini
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD) .* HTTP/\d+\.\d+" (403|404|444) .*$
ignoreregex =
```

И `/etc/fail2ban/filter.d/wp-auth.conf`:

```ini
[Definition]
failregex = ^<HOST> .* "POST .*wp-login.php HTTP/\d+\.\d+".*$
ignoreregex =
```

После чего перезапустить `fail2ban` и убедиться, что при его запуске не возникли никакие ошибки:

```bash
$ service fail2ban restart
$ cat /var/log/fail2ban.log | grep ERROR
```

## Полевые тестирования

Теперь давай попробуем проверить, насколько наши меры эффективны. Будем использовать онлайн-сканер [WordPress Security Scan](https://hackertarget.com/wordpress-security-scan/) и WPScan собственной персоной.

Результаты "WordPress Security Scan":

До  | После
--- | -----
![scr](https://hsto.org/files/0b1/41a/fc6/0b141afc6de049b496b760b1ae0c7d50.png) | ![scr](https://hsto.org/files/a1e/b6a/bb8/a1eb6abb86f44a7d91b27dcbb7194773.png)

Вывод WPScan **до** (_под символами X скрыты актуальные значения, соответственно_):

```bash
$ wpscan -r --url somedomain.com

[+] URL: http://somedomain.com/
[+] Started: Sun Jul 1 01:01:01 2015

[+] robots.txt available under: 'http://somedomain.com/robots.txt'
[+] Interesting entry from robots.txt: http://somedomain.com/*/wp-*
[+] Interesting entry from robots.txt: http://somedomain.com/*/feed/*
[+] Interesting entry from robots.txt: /*/*?s=*
[+] Interesting entry from robots.txt: http://somedomain.com/*/*.js$
[+] Interesting entry from robots.txt: http://somedomain.com/*/*.inc$
[+] Interesting entry from robots.txt: http://somedomain.com/*/trackback/*
[+] Interesting entry from robots.txt: http://somedomain.com/*/xmlrpc.php
[+] Interesting header: SERVER: XXXXXXXXX

[+] WordPress version 4.X.X identified from advanced fingerprinting

[+] WordPress theme in use: null

[+] Name: null
    Location: http://somedomain.com/wp-content/themes/null/
    Style URL: http://somedomain.com/wp-content/themes/null/style.css
    Theme Name: /dev/null
    Description:

[+] Enumerating plugins from passive detection ...
    3 plugins found:

[+] Name: XXXXXXXXXXXXX
    Location: http://somedomain.com/wp-content/plugins/XXXXXXXXXXXXX/

[+] Name: XXXXXXXXXXXXXX - vX.XX
    Location: http://somedomain.com/wp-content/plugins/XXXXXXXXXXXXXX/
    Readme: http://somedomain.com/wp-content/plugins/XXXXXXXXXXXXXX/readme.txt

[+] Name: XXXXXXXXXXXXXXX
    Location: http://somedomain.com/wp-content/plugins/XXXXXXXXXXXXXXX/

[+] Finished: Sun Jul 1 01:01:43 2015
[+] Requests Done: 112
[+] Memory used: 6.102 MB
[+] Elapsed time: 00:00:42
```

И результат её же работы, но **после**:

```bash
$ wpscan -r --url somedomain.com

[+] URL: http://somedomain.com/
[+] Started: Sun Jul 1 01:01:01 2015

[+] Interesting header: SERVER: XXXXXXXXX

[i] WordPress version can not be detected

[+] WordPress theme in use: null

[+] Name: null
    Location: http://somedomain.com/wp-content/themes/null/

[!] The target seems to be down
```

Профит? Отож :) Для того чтоб скрыть баннер фронтэнд сервера необходимо собрать nginx из исходников, процесс сборки был ранее описан в [этой записи][nginx-compile-from-sources].

## Вместо заключения

Не существует такой системы, которую невозможно взломать, и об этом стоит помнить. Никто не отменял XSS уязвимости которые находятся с завидной периодичностью, а также стоит помнить что существуют критичные уязвимости, которые публично нигде не освещены. Для раскрытия той же версии WP методом `fingerprint`-а существует так же большое количество методов в целом.

В данной заметке мы рассмотрели лишь некоторые из наиболее популярных.

Будьте бдительны, своевременно обновляйтесь и будьте оригинальны в методах своей защиты - сделайте жизнь скрипткидди интереснее ;)

[nginx-compile-from-sources]: {{< ref "nginx-compile-from-sources.md" >}}
[make-wp-more-secure-with-nginx]: {{< ref "make-wp-more-secure-with-nginx.md" >}}
[remove-wp-version]: {{< ref "remove-wp-version.md" >}}
[make-wp-more-secure-part1]: {{< ref "make-wp-more-secure-part1.md" >}}
