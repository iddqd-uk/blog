---
title: Настройка iptables для swarm кластера
slug: iptables-for-docker-swarm
date: 2020-07-06T15:11:47Z
aliases: [/adm/iptables-for-docker-swarm]
image: featured-image.jpg
categories: [adm]
tags:
  - linux
  - iptables
  - swarm
  - docker
  - security
---

Однажды я решил поднять свой крохотный кластер для приложений, запускаемых в docker-контейнерах. Выбор был между [nomad](https://www.nomadproject.io/) _(уже не один комрад его настоятельно рекомендовал - обязательно попробую, но позже)_, [K8S](https://kubernetes.io/) _(слишком сложно и дорого по ресурсам для pet-проекта)_ и [Docker Swarm](https://docs.docker.com/engine/swarm/) _(никакого дополнительного софта не потребуется, поставляется вместе с самим докером)_. Как ты понимаешь - выбор пал именно на последний.

По тому как его поднять и базово настроить - материалов полно, но когда дело дошло до настройки огненной стены - вот тут начались некоторые трудности. Известно, что `docker` активно эксплуатирует сетевые интерфейсы и `iptables` для управления трафиком между сетями и контейнерами. Как настроить ограничения доступа к master и worker-нодам кластерам ниже мы и поговорим.

Итак, мы имеем:

- `internal`-сеть `10.10.10.0/24`, к которой подключены все наши серверы - она используется как внутренняя (без ограничений) для общения сервером между собой (при создании swarm был указан сетевой интерфейс, "смотрящий" в этй сеть `docker swarm init --advertise-addr ens11`)
- Каждый сервер имеет белый "внешний" IP адрес (на сетевом интерфейсе `eth0`)
- Один сервер в роли `master`-ноды swarm-а - он же выполняет роль точки входа _(ingress)_ в ресурсы кластера, т.е. весь трафик (http(s), tcp, udp) приходит на него и дальше уже перенаправляется в нужные контейнеры балансируя нагрузку (на этом сервере открываются **все необходимые** порты, что должны "светиться" наружу, естественно, и ssh для административного доступа). Сами контейнеры, что будут обрабатывать трафик находятся на `worker`-нодах
- Два сервера в роли `worker`-ов - на них то и запускаются приложения в контейнерах, что обрабатывают наши запросы (tcp/udp пакеты)

Нам нужно:

- Не ограничивать **исходящий** трафик на серверах на `eth0` интерфейсе - любой процесс должен без ограничений ходить в глобальную сеть
- Закрыть входящие на всех портах `eth0`, кроме явно разрешенных (в нашем случае это будет только ssh на `worker`-нодах и `http\https\ssh` на `master`)
- Для `internal`-сети на интерфейсе `ens11` не вводить никаких ограничений
- При запуске docker-контейнера, даже с публикацией порта в хост (`network: host`) - не открывать этот порт "наружу" (для этого нужно будет явно добавить правило исключения и только на `master`-ноде)

## `worker`

Аналогична для всех `worker`-нод в кластере. Перед выполнением каких-либо манипуляций c `iptables` настоятельно рекомендую (читай - обязательно) вывести ноду из работы, для чего на `master` выполни (подставляя имя или ID нужной ноды):

```bash
$ docker node ls
ID                            HOSTNAME    STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
m0au96xa2pfiwxhdhweux5b92 *   ingress-1   Ready     Active         Leader           19.03.12
sweebuhuzfnr2bygrwg4jxddn     node-1      Ready     Active                          19.03.12
5ikrj3ugkdiublkfe70j9upad     node-2      Ready     Active                          19.03.12

$ docker node update node-1 --availability drain
```

А по **завершению** работ обратно вводи ноду в строй:

```bash
$ docker node update node-1 --availability active
```

Итак, ставим `iptables-persistent` (все, что ниже выполняется уже на самой `worker`-ноде):

```bash
$ apt install iptables-persistent
$ cd /etc/iptables
```

И приводим файлы `rules.v4` и `rules.v6` к следующему состоянию (правим только `filter`, оставил только нужные изменения):

```bash
$ cat ./rules.v4

# ...
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:CHECKS - [0:0] # added
# ...
-A INPUT -i eth0 -j CHECKS
-A FORWARD ...
-A CHECKS -p tcp -m tcp --dport 22 -m comment --comment SSH -j ACCEPT
-A CHECKS -m state --state RELATED,ESTABLISHED -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 3 -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 11 -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 8 -m limit --limit 8/sec -j ACCEPT
-A CHECKS -j DROP
-A DOCKER ...
-A DOCKER-ISOLATION-STAGE-1 ...
-A DOCKER-ISOLATION-STAGE-2 ...
-A DOCKER-USER -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-USER -i eth0 -j DROP
COMMIT
# ...
```

> Для IPv6 пример взят [отсюда](https://community.hetzner.com/tutorials/debian-10-docker-install-dual%20stack-ipv6nat-firewall#step-33---create-basic-firewall-rules)

```bash
$ cat ./rules.v6

#...
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
:WCFW-ICMP - [0:0]
:WCFW-Local - [0:0]
:WCFW-Services - [0:0]
:WCFW-State - [0:0]
-A INPUT -j WCFW-Local
-A INPUT -j WCFW-State
-A INPUT -p ipv6-icmp -j WCFW-ICMP
-A INPUT -j WCFW-Services
-A OUTPUT -j WCFW-Local
-A OUTPUT -j WCFW-State
-A OUTPUT -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 1 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 2 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 3 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 4 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 133 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 134 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 135 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 136 -j ACCEPT
-A WCFW-ICMP -p ipv6-icmp -m icmp6 --icmpv6-type 128 -m limit --limit 8/sec -j ACCEPT
-A WCFW-Local -i lo -j ACCEPT
-A WCFW-Services -i eth0 -p tcp -m tcp --dport 22 -m comment --comment SSH -j ACCEPT
-A WCFW-State -m conntrack --ctstate INVALID -j DROP
-A WCFW-State -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
COMMIT
# ...
```

После чего заставляем `iptables` использовать наши правила:

```bash
$ iptables-restore ./rules.v4
$ ip6tables-restore ./rules.v6
```

## `master`

Аналогично с `worker`-ами ставим `iptables-persistent` и приводим к виду:

```bash
$ cat ./rules.v4

# ...
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:CHECKS - [0:0] # added
# ...
-A INPUT -i eth0 -j CHECKS
-A FORWARD ...
-A CHECKS -p tcp -m tcp --dport 22 -m comment --comment SSH -j ACCEPT
-A CHECKS -p tcp -m tcp --dport 80 -m comment --comment HTTP -j ACCEPT
-A CHECKS -p tcp -m tcp --dport 443 -m comment --comment HTTPS -j ACCEPT
-A CHECKS -m state --state RELATED,ESTABLISHED -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 3 -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 11 -j ACCEPT
-A CHECKS -p icmp -m icmp --icmp-type 8 -m limit --limit 8/sec -j ACCEPT
-A CHECKS -j DROP
-A DOCKER ...
-A DOCKER-ISOLATION-STAGE-1 ...
-A DOCKER-ISOLATION-STAGE-2 ...
-A DOCKER-USER -i eth0 -p tcp -m tcp -m conntrack --ctorigdstport 80 -m comment --comment HTTP -j ACCEPT
-A DOCKER-USER -i eth0 -p tcp -m tcp -m conntrack --ctorigdstport 443 -m comment --comment HTTPS -j ACCEPT
-A DOCKER-USER -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-USER -i eth0 -j DROP
COMMIT
# ...
```

Для IPv6 настройки оставил аналогичными с `worker`-нодами. Теперь так выполняем:

```bash
$ iptables-restore ./rules.v4
$ ip6tables-restore ./rules.v6
```

И проверяем **извне** на предмет "осталось ли что-нибудь лишнее":

```bash
$ nmap -v -A -p1-65535 -Pn 11.22.22.11
```

Где `11.22.22.11` наш белый IP сервера (производим такие манипуляции с каждым сервером) - должны остаться открытые только нужные нам порты. Проверяем и корректность работы приложений, запущенных в кластере (те, что ходят в глобальную сеть - должны успешно в неё ходить). Так же проверяем и с самих севреров (как `master`, так и `worker`):

```bash
$ ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=20.2 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=57 time=20.3 ms

$ ping6 2606:4700:4700::1111
PING 2606:4700:4700::1111(2606:4700:4700::1111) 56 data bytes
64 bytes from 2606:4700:4700::1111: icmp_seq=1 ttl=56 time=21.1 ms
64 bytes from 2606:4700:4700::1111: icmp_seq=2 ttl=56 time=21.3 ms

$ docker run --rm alpine:latest ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1): 56 data bytes
64 bytes from 1.1.1.1: seq=0 ttl=56 time=20.531 ms
64 bytes from 1.1.1.1: seq=1 ttl=56 time=20.386 ms

$ docker run --rm curlimages/curl -s ipinfo.io/ip
11.22.22.11

$ curl -s ipinfo.io/ip
11.22.22.11
```

### Ссылки по теме

- [Limiting outside connections to docker container with iptables](https://serverfault.com/a/933803)
- [Docker and iptables](https://docs.docker.com/network/iptables/#add-iptables-policies-before-dockers-rules)
- [Сети Docker изнутри: как Docker использует iptables и интерфейсы Linux](https://habr.com/ru/post/333874/)
- [Пользовательские правила iptables для docker на примере zabbix](https://habr.com/ru/post/473222/)
- [Install Docker CE on Debian 10 with Dual stack IPv6-NAT and Firewall Support](https://community.hetzner.com/tutorials/debian-10-docker-install-dual%20stack-ipv6nat-firewall)
