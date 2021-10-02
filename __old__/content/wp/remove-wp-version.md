---
title: Скрываем версию WordPress
date: 2015-05-26T07:10:53+00:00
aliases:
  - /wp/remove-wp-version.html
featured_image: /images/posts/hide-wp-version-wide.jpg
tags:
  - php
  - plugin
  - security
  - wordpress
---

Маленький но довольно полезный плагин для повышения безопасности сайта на WordPress, который всё что делает - это скрывает версию CMS, удаляя:

- Во-первых теги `<meta generator="..." />` (и иже с ними), что генерирует сам Wordpress;
- Во-вторых из запросов к css и js файлам подстроку `?ver=%версия%`, которая всё беспощадно палит.

<!--more-->

Делается также при помощи активации простого плагина:

{{< gist tarampampam a011dd4c62b1f7121991 >}}

Для установки через ssh:

```bash
$ cd /path/to/wp-content/plugins
$ wget -O remove-wp-version.php https://goo.gl/5NMw9b
```

Или приведенный выше код можно разместить в файле `functions.php` вашей темы.

### А ещё?

Раз уж такая пьянка - давай добавим в конфиг nginx следующие строки, которые предотвратят раскрытие версии после очередного обновления WP (или какого-либо плагина) путем чтения ридмишки или файла лицензии:

```nginx
server {
  # ...

  # Запрещаем доступ ко всем ULR-ам, которые заканчиваются следующими вхождениями
  location ~* /(readme.(html|txt|md)|license.(html|txt|md))$ {return 444;}

  # ...
}
```
