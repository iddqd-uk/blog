---
title: Повышение безопасности WordPress с помощью nginx
date: 2015-05-05T05:45:15+00:00
aliases:
  - /wp/make-wp-more-secure-with-nginx.html
featured_image: /images/posts/wp-secure-wide.jpg
tags:
  - nginx
  - security
  - wordpress
---

> Первая часть доступна по [этой ссылке][1]. Так же у данного поста имеется **обновленная** версия [этой ссылке][2]

Проанализировав логи одного блога на WordPress заметил, что присутствует довольно большое количество запросов к страницам, которых не существует. Посмотрев внимательнее стало очевидно, что имеет место как сбор данных как об используемой CMS, так и попытки эксплуатировать различные уязвимости плагинов, тем и самого WP.

<!--more-->

Запрошенные страницы имели примерно следующий вид:

```bash
/wp-admin/admin-ajax.php?action=revslider_show_image&img=../wp-config.php
/wp-admin/admin-ajax.php?action=revolution-slider_show_image&img=../wp-config.php
/wp-content/themes/infocus/lib/scripts/dl-skin.php
/wp-admin/admin-ajax.php?action=showbiz_show_image&img=../wp-config.php
/wp-content/plugins/google-mp3-audio-player/direct_download.php?file=../../../wp-config.php
/wp-admin/admin-ajax.php?action=kbslider_show_image&img=../wp-config.php
/wp-content/themes/parallelus-mingle/framework/utilities/download/getfile.php?file=../../../../../../wp-config.php
/wp-content/plugins/db-backup/download.php?file=../../../wp-config.php
/wp-admin/admin-ajax.php?action=revslider_ajax_action&img=../wp-config.php
/wp-content/plugins/wp-filemanager/incl/libfile.php?path=../../&filename=wp-config.php&action=download
/wp-content/themes/churchope/lib/downloadlink.php?file=../../../../wp-config.php
/magmi/web/plugin_upload.php
```

> Для повышения безопасности мы будем использовать **nginx**, путем добавления описанных ниже правил в секцию `server {...}` нашего блога

Как наиболее очевидное решение - блокировать все URL, которые содержат ключевые слова `/wp-config.php`. Пойдем чуть дальше и расширим этот список названиями некоторых потенциально уязвимых плагинов, важных системных файлов, ридмишкам и файлам лицензионного соглашения _(для предотвращения возможного раскрытия версии)_:

```nginx
# Запрещаем доступ ко всем ULR-ам, которые содержат следующие вхождения
location ~* /((wp-config|plugin_upload|dl-skin|uploadify|xmlrpc).php|readme.(html|txt|md)|license.(html|txt|md)|(.*)/(revslider|showbiz|infocus|awake|echelon|elegance|dejavu|persuasion|wp-filemanager|churchope|uploadify)/(.*))$ {
  return 444;
}
```

> Стоит учесть, если вы используете какой-либо плагин из перечисленного в правиле списка, то он наверняка перестанет работать. Более того - закрываем доступ к `xmlrpc.php` (часто используемого для DDOS сайта), после чего приложения-клиенты для WP наверняка перестанут работать

Далее - блокируем все URL, в параметрах которых присутствуют ключевые слова `wp-config.php`, `xmlrpc.php` и другие ключи, плюс к тому - усложним эксплуатацию наиболее популярных SQL-инъекций:

```nginx
# Запрещаем все URL-ы, в параметрах (..?a=evil) которых есть следующие вхождения
if ($query_string ~* "^(.*)(wp-config.php|dl-skin.php|xmlrpc.php|uploadify.php)(.*)$") {
  return 444;
}

# Для противодействия SQL-инъекциям <https://habr.com/company/xakep/blog/259843/>
if ($query_string ~* "(concat.*\(|union.*select.*\(|union.*all.*select)") {
  return 444;
}
```

Запрещаем доступ к php файлам, которые были загружены в директорию `uploads` или `files`:

```nginx
# Запрет для загруженных скриптов
location ~* /(?:uploads|files)/.*\.php$ {
  return 444;
}
```

Хардкорно закрываем доступ к листингу определенных директорий, которые раскрывают используемую CMS и данные, несколько облегчающие взлом сайта:

```nginx
# Закрываем доступ к корню следующих директорий
location = /wp-content/ {return 404;}
location = /wp-includes/ {return 404;}
location = /wp-content/plugins/ {return 404;}
location = /wp-content/themes/ {return 404;}
location = /wp-content/languages/ {return 404;}
location = /wp-content/languages/plugins/ {return 404;}
location = /wp-content/languages/themes/ {return 404;}
```

Закрываем доступ к путям ведущим к корневым директориям плагинов, тем самым усложняя их раскрытие путем перебора:

```nginx
# Закрываем прямой доступ у содержимому корневых директорий плагинов (для усложнения их раскрытия)
location ~* /wp-content/plugins/([0-9a-z\-_]+)(/|$) {
  return 404;
}
```

Закрываем доступ к файлам перевода, которые так же раскрывают версию CMS:

```nginx
# Закрываем доступ к файлам перевода (для невозможности раскрыть версию WP)
location ~ /wp-content/languages/(.+)\.(po|mo) {
  return 404;
}
```

И мы пойдем ещё чуть дальше, отсеив значительное количество различных онлайн-сканеров и веб-аналитику:

```nginx
if ($http_user_agent ~* (nmap|nikto|wikto|sf|sqlmap|bsqlbf|w3af|acunetix|havij|appscan|monoid.nic.ru|Web-Monitoring|semalt|Baiduspider|virusdie|wget|indy|perl)) {
  return 403;
}
```

> Обрати внимание, что в списке есть `wget` - после применения данного правила простым wget-ом (без указания отличного от `wget` `useragent`-а) с сайта уже ничего не скачаешь

После чего перезапускаем nginx, и проверяем **не**доступность как приведенных выше в качестве примера путей, так и корректность работы WP в целом.

> У данного поста имеется обновленная версия [этой ссылке][2]

[1]: {{< ref "make-wp-more-secure-part1.md" >}}
[2]: {{< ref "total-wordpress-secutity.md" >}}
