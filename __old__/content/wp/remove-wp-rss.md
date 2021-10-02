---
title: Отключаем RSS в WordPress
date: 2015-05-25T16:28:30+00:00
aliases:
  - /wp/remove-wp-rss.html
featured_image: /images/posts/disable-wp-rss-wide.jpg
tags:
  - php
  - plugin
  - wordpress
---

В ряде случаев для сайта на WordPress совершенно не требуется RSS лента. Отключив эту возможность мы не только освобождаем дополнительные ресурсы системы (_нет необходимости формировать фид, т.к. его не запрашивают только ленивые боты_), но и усложним задачу тем, кто уже сейчас (_или собирается_) грабит наш контент.

<!--more-->

Делается это при помощи активации очень простого плагина, ~~кот~~ код которого предоставлен ниже:

{{< gist tarampampam 51d473b23382904394b1 >}}

Для установки через ssh:

```bash
$ cd /path/to/wp-content/plugins
$ wget -O remove-wp-version.php https://goo.gl/uk7Afn
```

Так же приведенный выше код можно разместить в файле `functions.php` вашей темы. Тоже замечательно будет работать.

#### А если совсем-совсем запретить

А для того чтоб совсем-совсем запретить доступ к фиду - в конфиг нашего nginx добавляем:

```nginx
server {
  # ...

  # Запрещаем RSS и прочие фиды <https: //codex.wordpress.org/WordPress_Feeds>
  location ~* /(rss(|2)(|/)|rdf(|/)|atom(|/)|feed(|/(|rss(|2)|rdf|atom)))$ {return 444;}
  if ($query_string ~* "^(.*)feed=(rss(|2)|rdf|atom)(.*)$") {return 444;}

  # ...
}</https:>
```
