---
title: Маленькая хитрость iptables
date: 2015-07-14T08:59:58+00:00
aliases:
  - /adm/little-iptables-tips.html
featured_image: /images/posts/iptables-tips-wide.jpg
tags:
  - bash
  - centos
  - iptables
  - nmap
  - security
---

При сканировании портов целевой системы можно довольно часто наблюдать результат вида:

```bash
...
8080/tcp  filtered http-proxy
...
```

Что говорит нам о том что порт наверняка используется системой, но "прикрыт" извне. Не смотря на то что работать с ним врятли будет возможно - он всё же дает исследуемому дополнительную информацию о исследуемой системе.

Как проще всего прикрыть порт извне используя `iptables`?

```bash
$ iptables -A INPUT -p tcp --dport %номер_порта% -j DROP
```

А как можно прикрыть его так, чтоб он был недоступен только лишь извне, да ещё и не отображался в результатах `nmap` как `filtered`?

```bash
$ iptables -A INPUT ! -s 127.0.0.1/8 -p tcp --dport %номер_порта% -j REJECT --reject-with tcp-reset
```

> Если по-человечески, то это означает:
>
> Для всех входящих пакетов (кроме локального хоста (`127.0.0.1/8`)), приходящих по протоколу `tcp` на порт `%номер_порта%` ответить ICMP уведомлением `tcp-reset`, после чего пакет будет "сброшен".
>
> Так же возможны варианты ICMP ответа: `icmp-net-unreachable`, `icmp-host-unreachable`, `icmp-port-unreachable`, `icmp-proto-unreachable`, `icmp-net-prohibited` и `icmp-host-prohibited`.

После чего не забудьте выполнить:

```bash
$ service iptables save
$ service iptables restart
```

> Для выполнения `$ service iptables save` в системе должен присутствовать пакет `iptables-services`
>
> Если в системе работает `fail2ban` обязательно перед выполнением `$ service iptables save` остановите его, выполнив `$ service fail2ban stop`
