---
title: WD Green + Linux = отключение парковки головок диска
aliases:
  - /my-book-live/wd-green-disable-head-parking.html
date: 2014-07-19T18:58:00+00:00
featured_image: /images/posts/wd-green-wide.jpg
tags:
- debian
- green
- linux
- mbl
- wd
- WD My Book Live
- western digital
---

На системе Debian GNU/Linux 5.0, а если точнее — WD My Book Live. Зачем это делать — подробно написано [на хабре]. А если в цифрах моей железки, то за пол-года эксплуатации:

```bash
$ smartctl -a /dev/sda | grep Load_Cycle_Count
193 Load_Cycle_Count 0x0032 180 180 000 Old_age Always - **62035**
```

<!--more-->

По идее — надо собрать [утилиту из исходников], но для этого нужны либы и gcc. Для них — нужны определенные пакеты с зависимостями. Для пакетов — ключи репозитория. Для ключей — либы. Ну вы поняли. Скорее всего это кривизна моих рук, но после всех шаманств с `/etc/apt/sources.list` и экспериментов — у меня нихера не получалось.

До одного момента. Пока не наткнулся на статью с уже собранной и приготовленной к использованию утилитой: [How to Hack WD My Book Live]. Всё оказалось более чем просто:

```bash
$ wget http://mybookworld.wikidot.com/local--files/mybook-live/idle3ctl.tar.gz
$ tar zxvf idle3ctl.tar.gz
$ ./idle3ctl -d /dev/sda
$ reboot
```

[на хабре]: https://habr.com/post/106273/
[утилиту из исходников]: http://sourceforge.net/p/idle3-tools/code/HEAD/tree/trunk/
[How to Hack WD My Book Live]: http://colekcolek.com/2011/12/20/hack-wd-book-live/
