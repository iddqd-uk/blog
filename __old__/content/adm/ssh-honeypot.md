---
title: SSH Honeypot — просто и со вкусом
date: 2015-07-13T11:13:57+00:00
aliases:
  - /adm/ssh-honeypot.html
featured_image: /images/posts/ssh-honeypot-wide.jpg
tags:
  - ban
  - bash
  - centos
  - fail2ban
  - iptables
  - linux
  - security
  - shell
  - ssh
---

> **Honeypot («Ловушка»)** (англ. горшочек с мёдом) — ресурс, представляющий собой приманку для злоумышленников. ([wikipedia.org](https://ru.wikipedia.org/wiki/Honeypot))

Одно из первых средств, которое применяется для аудита целевых систем - это сканирование портов с целью выявления, какие же службы (_сервисы_) там крутятся. Можете даже сейчас натравить `nmap` на свой сервер и посмотреть, что же он нам о нем расскажет. Самый простой пример результата его работы:

<!--more-->

```bash
$ nmap google.com

Starting Nmap 6.47 ( http://nmap.org ) at 2050-01-11 00:00 GMT
Nmap scan report for google.com (173.194.71.138)
Host is up (0.010s latency).
Other addresses for google.com (not scanned): 173.194.71.139 173.194.71.113 173.194.71.101 173.194.71.100 173.194.71.102
rDNS record for 173.194.71.138: lb-in-f138.1e100.net
Not shown: 998 filtered ports
PORT    STATE SERVICE
80/tcp  open  http
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 4.92 seconds
```

Из которого мы видим, что на целевой системе открыты 2 порта (_стелс-сканирование и прочее мы пока опустим - не к чему оно сейчас_): **80**/tcp и **443**/tcp и это означает, что там наверняка крутится web-сервер, который работает по **http** и **https**.

Теперь подойдем к более интересному моменту.

Довольно часто администраторы используют для доступа к своим серверам **SSH**. Стандартный порт для SSH - **22**/tcp. Если администратор хоть чуть-чуть "шарит", то после установки системы он сразу же перевешивает SSH на **не** стандартный порт (_например `454545`_), запрещает логин от рута и настраивает авторизацию по сертификату вместо пароля. И оно совершенно правильно - держать SSH на стандартном порту, да без какой-либо дополнительной защиты - потенциально огромная брешь в безопасности.

А что если повесить на этот самый `22` порт ещё один ssh-демон, но при этом все попытки логина по нему сразу отправлять в fail2ban? Обычным нашим пользователям SSH не нужен, мы ходим через порт `454545`, значит тот, кто будет ломиться на `22` порт - бот или злоумышленник, которого необходимо забанить по IP на довольно длительное время. Обойти это ограничение можно будет лишь заюзав VPN, прокси или другое средство смены IP, ну или дождаться пока не пройдет время бана которое мы установим.

Данную задачу будем решать в 3 этапа:

  1. Настроим и запустим дополнительный **sshd**-демон, который будет висеть на `22` порту;
  2. Настроим **fail2ban**, который будет читать логи на попытку коннекта по ssh на `22` порту;
  3. Поставим всё это дело в автозапуск;

> Все манипуляции буду производить на CentOS 7, разница с другими дистрибутивами - минимальна

## Настройка и запуск дополнительного sshd-демона

Считаем, что `sshd` у нас уже сейчас настроен и висит на отличном от `22` порту. Переходим в директорию с его конфигами и создаем новый конфиг для honeypot:

```bash
$ cd /etc/ssh
$ nano ./sshd_config_honeypot
```

Пишем в него следующее (_самые интересные моменты пометил желтым цветом_):

```ini
Port 22
AddressFamily inet
SyslogFacility AUTH
LogLevel VERBOSE

PermitRootLogin no
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
IgnoreUserKnownHosts yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no
X11Forwarding no
UsePAM yes
UseDNS no
AllowUsers nobody

MaxAuthTries 1
MaxSessions 1
```

И после чего запускаем новый экземпляр `sshd`, но работающий именно с этим конфигом:

```bash
$ /usr/sbin/sshd -f /etc/ssh/sshd_config_honeypot
$ ps ax | grep sshd
  803 ?        Ss     0:00 /usr/sbin/sshd -D
 2549 ?        Ss     0:00 /usr/sbin/sshd -f /etc/ssh/sshd_config_honeypot
14627 ?        Ss     0:00 sshd: root@pts/1
14804 pts/1    R+     0:00 grep --color=auto sshd
$ iptables -L -n  | grep ':22'
$
```

> Для остановки демона можно выполнить (где `2549` это `PID` нашего процесса):
>
```bash
$ kill 2549
```

Если демон у нас корректно запустился - в STDOUT/STDERR ничего критично не сказал, в процессах успешно завертелся, `iptables` у нас `22` порт не блокирует, пробуем подключиться к серваку с нашей машины:

```bash
$ ssh -p 22 -l nobody 2.2.2.2
Permission denied (publickey).
```

И тут де чекаем лог на сервере:

```bash
$ tail -n40 /var/log/messages | grep sshd
Jul 13 12:03:28 zero sshd[14869]: Connection from 1.1.1.1 port 1277 on 2.2.2.2 port 22
Jul 13 12:03:28 zero sshd[14869]: Connection closed by 1.1.1.1 [preauth]
```

Если у тебя картина выгляди аналогично, значит всё работает как надо :) Попытки авторизации у нас обламываются, лог корректно пишется.

## Настройка fail2ban

Переходим в директорию с fail2ban и первым делом создаем новый фильтр:

```bash
$ cd /etc/fail2ban
$ nano ./filter.d/sshd-honeypot.conf
```

```ini
# Example:
# Jul 13 09:18:28 zero sshd[8625]: Connection from 1.1.1.1 port 1218 on 2.2.2.2 port 22

[Definition]
failregex = ^.+ sshd\[\d+\]: (C|c)onnection from <HOST> port \d+ on \d+\.\d+\.\d+\.\d+ port 22$
ignoreregex =
```

Сохраняем, проверяем работоспособность фильтра (_важно, чтобы `matched` было не равно нулю, но и не было сильно больше количества наших попыток коннектов по ssh_):

```bash
$ fail2ban-regex /var/log/messages /etc/fail2ban/filter.d/sshd-honeypot.conf | grep matched
Lines: 2001 lines, 0 ignored, 1 matched, 2000 missed [processed in 0.20 sec]
```

После чего добавляем новый `jail` (`/etc/fail2ban/jail.local`):

```ini
[ssh-honeypot]
enabled  = true
filter   = sshd-honeypot
action   = iptables-allports[name="ssh_honeypot", protocol="all"]
maxretry = 1
findtime = 10
# 86400 is 1 day, 259200 is 3 days
bantime  = 259200
logpath  = /var/log/messages
```

> Настоятельно рекомендую добавить свой IP адрес в `ignoreip` (_секции `[DEFAULT]`_), так как есть риск забанить себя на трое суток :) Формат записи следующий (использую `1.1.1.0/8` т.к. IP серый):
>
> ```ini
> [DEFAULT]
> ignoreip = 127.0.0.1/8 2.2.2.2 1.1.1.0/8
> ```
>
> Или как минимум выставить `bantime` равным, например, `30` (секундам) - достаточно для того, чтобы проверить и при этом не получить массу неудобств.

Перезапускаем fail2ban, проверяем лог:

```bash
$ service fail2ban restart
$ cat /var/log/fail2ban.log | grep ' ERROR '
```

Если лог у нас не содержит никаких критичных ошибок, то остается дело за малым - проверить, будет ли срабатывать правило. Cнова пытаемся приконнектиться к серверу с нашей машины:

```bash
$ ssh -p 22 -l nobody 2.2.2.2
```

Смотрим на появление строки похожей на следующую в логе fail2ban:

```bash
$ cat /var/log/fail2ban.log | grep ssh-honeypot
2050-01-11 01:00:00,000 fail2ban.filter [15038]: INFO [ssh-honeypot] Ignore 1.1.1.1 by ip
```

Если так оно и есть - значит всё отлично работает - наш IP не был забанен только потому, что он находится в списке игнорируемых :)

## Автозапуск

В автозапуске нуждается лишь наш дополнительный демон `sshd`, т.к. fail2ban у тебя и так наверняка уже стартует вместе с системой.

Добавим в файл `/etc/rc.local` следующую запись:

```bash
## sshd honeypot autostart
ssh_honeypot_config='/etc/ssh/sshd_config_honeypot';
if [ -f $ssh_honeypot_config ] && [ -x /usr/sbin/sshd ]; then
  /usr/sbin/sshd -f $ssh_honeypot_config;
fi;
```

Которая будет проверять наличие бинарника `sshd` и наличия нужного конфига. Если два этих условия выполняются, запускаем демона уже знакомым нам методом. Для верности можешь ребутнуть сервер и убедиться, что всё работает.

Теперь пускай все желающие ломятся на наш SSH - результат для них будет лишь один :)
