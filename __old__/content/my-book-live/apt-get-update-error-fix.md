---
title: Ошибка NO_PUBKEY
date: 2014-08-19T08:32:29+00:00
aliases:
  - /my-book-live/apt-get-update-error-fix.html
featured_image: /images/posts/mbl-wide.jpg
tags:
  - apt-get
  - linux
  - mbl
---

По умолчанию дистрибутив Debian на WD My Book Live - очень старый, и более не поддерживается. Исходя из этого - возникают ошибки apt-get. Как их исправить? Описано по [этой ссылке](http://en.kioskea.net/faq/809-debian-apt-get-no-pubkey-gpg-error), а так же дополнительно опишу решение здесь.

<!--more-->

Итак, мы запускаем и видим:

```bash
$ apt-get update
Get:1 http://archive.debian.org lenny Release.gpg [1034B]
Get:2 http://archive.debian.org lenny Release [99.6kB]
Get:3 http://ftp.us.debian.org squeeze Release.gpg [1655B]
Hit http://ftp.us.debian.org squeeze Release
Err http://ftp.us.debian.org squeeze Release
Ign http://archive.debian.org lenny Release
Get:4 http://archive.debian.org lenny/main Packages [5130kB]
Get:5 http://ftp.us.debian.org squeeze Release [96.0kB]
Ign http://ftp.us.debian.org squeeze Release
Ign http://ftp.us.debian.org squeeze/main Packages/DiffIndex
Get:6 http://ftp.us.debian.org squeeze/main Sources [4537kB]
Get:7 http://archive.debian.org lenny/main Sources [2679kB]
Hit http://ftp.us.debian.org squeeze/main Packages
Fetched 12.5MB in 26s (482kB/s)
Reading package lists... Done
W: GPG error: http://archive.debian.org lenny Release: The
following signatures were invalid: KEYEXPIRED 1337087218 The
following signatures couldnt be verified because the public key
is not available: NO_PUBKEY AED4B06F473041FA
W: GPG error: http://ftp.us.debian.org squeeze Release: The
following signatures couldnt be verified because the public key
is not available: NO_PUBKEY AED4B06F473041FA NO_PUBKEY
64481591B98321F9
W: You may want to run apt-get update to correct these problems
```

Первым делом, правим `/etc/apt/sources.list`:

```bash
deb http://archive.debian.org/debian/ lenny main
deb-src http://archive.debian.org/debian/ lenny main
deb http://ftp.us.debian.org/debian/ squeeze main
deb-src http://ftp.us.debian.org/debian/ squeeze main
```

Далее:

```bash
$ gpg --keyserver pgpkeys.mit.edu --recv-key AED4B06F473041FA
$ gpg -a --export AED4B06F473041FA | sudo apt-key add -
```

И подобную операцию повторяем с **каждым** ключом, на который apt-get ругается. После всего обновляем и видим что всё работает:

```bash
$ apt-get update
Hit http://archive.debian.org lenny Release.gpg
Hit http://archive.debian.org lenny Release
Hit http://ftp.us.debian.org squeeze Release.gpg
Ign http://archive.debian.org lenny/main Packages/DiffIndex
Hit http://ftp.us.debian.org squeeze Release
Ign http://archive.debian.org lenny/main Sources/DiffIndex
Hit http://archive.debian.org lenny/main Packages
Ign http://ftp.us.debian.org squeeze/main Packages/DiffIndex
Hit http://archive.debian.org lenny/main Sources
Ign http://ftp.us.debian.org squeeze/main Sources/DiffIndex
Hit http://ftp.us.debian.org squeeze/main Packages
Hit http://ftp.us.debian.org squeeze/main Sources
Reading package lists... Done
```
