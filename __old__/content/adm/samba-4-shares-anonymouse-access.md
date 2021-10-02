---
title: Samba 4 — доступ к публичным шарам без логина/пароля
date: 2015-08-10T06:57:07+00:00
aliases:
  - /adm/samba-4-shares-anonymouse-access.html
featured_image: /images/posts/samba-wide.jpg
tags:
  - linux
  - samba
---

Наткнулся на одну интересную особенность Samba 4, связанную с анонимным доступом к публичным шарам. Делается это для того, чтоб пользователи могли спокойно заходить на файл-сервер и не запариваться с вводом, например, пользователя `guest` и пустого пароля (_и в то же время существовали шары, доступ к которым возможен только после ввода пары `логин:пароль`_).

<!--more-->

Ранее (_до третьей версии включительно_) для реализации данной задачи мы пользовались указанием в секции `[global]` директивы `security = share`, а в секции самой шары - просто `guest ok = yes` и всё работало как надо. Теперь же надо делать чуть-чуть иначе, а именно:

**Необходимо использовать** директивы `security = user` и `map to guest = Bad Password` в секции `[global]`, а так-же указывать `guest ok = yes` в секции шары.

Дело в том, что директивы `security = share|server` считаются устаревшими, именно поэтому нам и остается пользоваться `security = user`. Для **отделения** же пользователя от гостя применяется новая директива `map to guest = Bad Password` (_смысл которой заключается в том, что если пользователь Samba существует в системе и введен неверный пароль, то вход этого пользователя отклоняется, если пользователя не существует, тогда ему присваивается статус гость_). Ну а для того чтобы открыть доступ к общему ресурсу для гостей осталась старая добрая директива `guest ok = yes` которую необходимо указывать непосредственно в секции шары.

Ниже полный пример настройки моей самбы:

```ini
[global]
  realm = WORKGROUP
  server string = Your server description

  # Setup charsets
  dos charset = cp1251
  unix charset = utf8

  # Disable printers
  load printers = No
  show add printer wizard = no
  printcap name = /dev/null
  disable spoolss = yes

  # Setup logging
  log file = /var/log/samba/smbd.log
  max log size = 50
  max xmit = 65536
  debug level = 1

  # Setup daemon settings
  domain master = No
  domain master = No
  preferred master = Yes
  socket options = IPTOS_LOWDELAY TCP_NODELAY SO_SNDBUF=65536 SO_RCVBUF=65536 SO_KEEPALIVE
  os level = 65
  use sendfile = Yes
  dns proxy = No
  dont descend = /proc,/dev,/etc
  deadtime = 15

  # Enable synlinks
  unix extensions = No
  wide links = yes
  follow symlinks = yes

  # Securtity settings
  security = user
  map to guest = Bad Password
  guest account = nobody
  auth methods = guest, sam_ignoredomain
  create mask = 0664
  directory mask = 0775
  hide dot files = yes

[public]
  comment = Public share
  path = /shares/public
  create mask = 0666
  directory mask = 0775
  read only = No
  guest ok = Yes

[user1]
  path = /shares/user1
  valid users = user1
  write list = user1

[user2]
  path = /shares/user2
  valid users = user2
  write list = user2
```

Для того, чтоб добавить в самбу пользователей можно воспользоваться `smbpasswd`:

```bash
$ smbpasswd -a user1
```

А для проверки корректности конфигов самбы:

```bash
$ testparm -s
```

> Все манипуляции проверялись на:
>
> ```bash
> $ yum list samba | grep samba
> samba.x86_64                      4.1.12-23.el7_1                       @updates
> ```
