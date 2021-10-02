---
title: Установка Linux на Chromebook
date: 2015-03-30T13:27:24+00:00
aliases:
  - /hard/install-linux-on-chromebook.html
featured_image: /images/posts/chrome-wide.jpg
tags:
  - chromebook
  - chromeos
  - linux
  - xubuntu
---

Приведу перечень нескольких простых шагов для выполнения данной задачи, на примере **Samsung Chromebook XE303C12**:

1. Осознаем, что всё что пользовательского на хромбуке есть - будет успешно утеряно;

1. Переключаемся в режим разработчика, нажимая `Ctrl` + `Refresh` + `Power`;

1. На экране входа подключаемся в WiFi, "Далее" **не** нажимаем, а жмем `Ctrl` + `Forward (F2)` для перехода в терминальную сессию;

1. Входим под `chronos` без какого-либо пароля, и вводим:

```bash
$ sudo chromeos-firmwareupdate --mode=todev
$ wget http://goo.gl/s9ryd
$ sudo bash ./s9ryd
```

1. Ждем.

На этом в общих чертах - всё. Очень рекомендую предварительно сделать [образ для восстановления ChromeOS](https://support.google.com/chromebook/answer/1080595?hl=ru) **перед** тем как пытаться что либо делать. Дальше - допиливания [согласно этому посту](https://chrubu.wordpress.com/2014/11/06/installing-ubuntu-14-10-on-the-samsung-arm-chromebook-series-3-xe303c12/).

А подводя итог - скажу **"Не стоит этого делать"**. Косяки с флешем, тачпадом, звуком, видео, с отрисовкой курсора, с некоторыми пакетами, быстродействием в целом.. Как человек, который только что откатился обратно на CromeOS - мой вердикт именно такой. Очень, очень жаль, правда.
