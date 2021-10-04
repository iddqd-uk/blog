---
title: "Обновляем SSH на Linux mint"
slug: update-ssh-linux-mint
date: 2019-01-31T16:25:45Z
featured_image: /images/posts/ssh-wide.png
tags:
- etc
- ssh
- linux
---

Так уж получается, что репозитории с пакетами частенько отстают в версиях ПО, которое предоставляют. Частный случай - нужно подключиться к удаленной системе используя не "традиционный" туннель, а [ssh jump](https://wiki.gentoo.org/wiki/SSH_jump_host). На борту Linux Mint 18.3 стоит `openssh`, который ещё не поддерживает эту фичу:

<!--more-->

```bash
$ ssh -V
OpenSSH_7.2p2 Ubuntu-4ubuntu2.4, OpenSSL 1.0.2g  1 Mar 2016

$ dpkg --list openssh\*
Name             Version
================-=====================
openssh-client   1:7.2p2-4ubuntu2.4
```

Простой путь вида `apt update && sudo apt install openssh-client` результата не возымел.

Чтож, давай поставим свежак из исходников! Тем более что делается это более чем просто (от рута):

```bash
$ apt update && apt install build-essential zlib1g-dev libssl-dev
$ wget -c 'https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.9p1.tar.gz'
$ tar -xzf openssh-7.9p1.tar.gz
$ cd openssh-7.9p1/
$ ./configure
$ make
$ service ssh stop
$ service sshd stop
$ make install
$ service sshd start && service sshd status
$ service ssh start && service ssh status
$ ssh -V
OpenSSH_7.9p1, OpenSSL 1.1.1a  20 Nov 2018
```

От теперь-то можно развернуться :)
