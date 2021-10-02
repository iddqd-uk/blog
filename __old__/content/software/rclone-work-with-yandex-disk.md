---
title: Дружим rclone с Яндекс.Диском
date: 2016-07-13T17:24:26+00:00
aliases:
  - /software/rclone-work-with-yandex-disk.html
featured_image: /images/posts/rclone-yandex-wide.jpg
tags:
  - backup
  - clouds
  - storage
  - sync
  - yandex
  - disk
---

Сегодня мы поговорим об одном интересном, простом в обращении и в какой-то мере уникальном инструменте. Знакомьтесь: [rclone](http://rclone.org/). Разработчики описывают его краткой и ёмкой фразой - "rsync для облачных хранилищ".

<!--more-->

Основная функция rclone - это синхронизация данных в хранилище и на локальной машине. Утилита несомненна окажется полезной для широкого круга пользователей облачного хранилища. Её можно использовать и для резервного копирования, и в работе со статическими сайтами, и для удобного доступа к файлам на яндекс.диске _(да и не только)_.

### Установка

Rclone может работать на различных ОС - Linux, Windows, MacOS, Solaris, FreeBSD, OpenBSD, NetBSD и Plan 9. В нашем случае мы будем рассматривать его установку на Linux-сервер _(CentOS 7 x64)_ с простой целью - дублировать файлы бэкапов в облаке яндекс.диска. Дистрибутивы под все доступные системы можно найти на [странице загрузок](http://rclone.org/downloads/).

Итак - качаем дистрибутив, распаковываем, и рассовываем файлы по директориям _(работал под рутом)_:

```bash
$ cd ~
$ wget http://downloads.rclone.org/rclone-current-linux-amd64.zip
$ unzip ./rclone-current-linux-amd64.zip
$ cd ./rclone-*-amd64/
$ cp ./rclone /usr/sbin/rclone && chmod 755 /usr/sbin/rclone
$ mkdir -p /usr/local/share/man/man1
$ cp ./rclone.1 /usr/local/share/man/man1/
$ mandb
```

### Настройка

Теперь нам придется поставить клиент rclone на свой десктоп с веб-браузером _(данный шаг можно совместить, если ставишь на машину с gui)_, так как для получения токена потребуется авторизоваться через браузер.

В нашем случае мы будем использовать windows-машину, для чего переходим на [страницу загрузок<](http://rclone.org/downloads/) и скачал скачиваем соответствующий клиент.

Из архива извлекаем бинарник `rclone.exe` и размещаем его в корне диска `c:\`. После чего запускаем `cmd` и в консоли выполняем:

```bash
cd /d c:\
c:\> rclone.exe config

No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n

name> yandex

client_id> # Оставляем пустым

client_secret> # Тоже оставляем пустым

Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine
y) Yes
n) No
y/n> y

# Открывается окно браузера, в котором вводим логин:пароль от учетки ЯД

Waiting for code...
Got code
--------------------
[yandex]
client_id =
client_secret =
token = {"access_token":"AQA...OuQ","token_type":"bearer","expiry":"2017-0..02+00:00"}
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y

Current remotes:
Name                 Type
====                 ====
yandex               yandex
e) Edit existing remote
n) New remote
d) Delete remote
s) Set configuration password
q) Quit config
e/n/d/s/q> q

c:\> rclone.exe --help

# Смотрим строку --config string  Config file. (default "C:\\Users\\USERNAME/.rclone.conf")

c:\> type C:\Users\USERNAME\.rclone.conf

[yandex]
type = yandex
client_id =
client_secret =
token = {"access_token":"AQA...OuQ","token_type":"bearer","expiry":"2017-0..02+00:00"}
```

Теперь нужно этот конфиг _(что был выведен крайней командой)_ перенести на наш сервер, для чего его нежно копируем в буфер обмена, и возвращаемся к терминалу:

```bash
$ rclone --help 2>&1 | grep -e '--config'
--config string  Config file. (default "/root/.rclone.conf")

# создаем конфиг по указанному пути и вставляем в него содержимое конфига с десктопа:
$ nano /root/.rclone.conf
```

### Проверка

Остается только проверить работу rclone путем создания на яндекс.диске директории средствами терминала, и синхронизации её с локальной директорией, где у нас хранятся бэкапы (в нашем примере это директория `/var/backups`):

```bash
# Проверяем
$ rclone lsd yandex:

# Создаем директорию для бэкапов, например
$ rclone mkdir yandex:backups

# И заливаем в неё (синхронизируем содержимое локального каталога с директорией в облаке):
$ rclone sync /var/backups yandex:backups
```

Теперь проверяем наличие файлов через веб-морду диска, и опционально ставим крайнюю команду в крон.
