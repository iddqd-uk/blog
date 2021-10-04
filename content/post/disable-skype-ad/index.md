---
title: Отключаем рекламу в Skype
slug: disable-skype-ad
date: 2015-02-10T17:20:00+00:00
aliases: [/tnt/disable-skype-ad]
image: featured-image.jpg
categories: [tnt]
tags:
  - bash
  - cmd
  - script
  - skype
  - windows
---

Всё предельно просто - необходимо запретить доступ к серверам, выдающим данные о рекламе, поправив файл `%SystemRoot%\system32\drivers\etc\hosts`, добавив в него записи вида:

<!--more-->

```bash
127.0.0.1 devads.skypeassets.net devapps.skype.net
127.0.0.1 qawww.skypeassets.net qaapi.skype.net
127.0.0.1 preads.skypeassets.net preapps.skype.net
127.0.0.1 static.skypeassets.com serving.plexop.net
127.0.0.1 preg.bforex.com ads1.msads.net
127.0.0.1 flex.msn.com apps.skype.com
127.0.0.1 api.skype.com rad.msn.com
127.0.0.1 adriver.ru
```

Рецепт был [найден на хабре][1].

Автоматизирующий это дело скрипт, который делает всё в 1 клик:

- [Скачать](https://raw.githubusercontent.com/tarampampam/scripts/master/win/Disable-Skype-ADBanners.cmd)
- [GitHub](https://github.com/tarampampam/scripts/blob/master/win/Disable-Skype-ADBanners.cmd)

[1]: https://habr.com/post/246709/#comment_8199867
