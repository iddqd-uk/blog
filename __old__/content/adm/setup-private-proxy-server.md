---
title: Поднимаем свой, приватный прокси-сервер
date: 2016-08-13T10:57:36+00:00
aliases:
  - /adm/setup-private-proxy-server.html
featured_image: /images/posts/your-proxy-wide.jpg
tags:
  - anonymous
  - centos
  - proxy
---

Сегодня мы будем поднимать анонимный и действительно шустренький proxy/socks сервер для себя-любимого. Так чтоб настроить его один раз, да и забыть - пускай пыхтит да нам на радость.

Будем считать что ты уже приобрел себе простенький vps, в качестве ОС выбрал Cent OS 7 и подцепился к нему по SSH, наблюдая девственную чистоту. Первым делом тюним SSH:

<!--more-->

```bash
# Первым делом меняем пароль, который мы получили в письме на новый:
$ passwd
# Перевешиваем SSH на порт 7788:
$ sed -i -r "s/#Port 22/Port 7788/" /etc/ssh/sshd_config
# Требуем вторую версию протокола и ограничиваем количество неудачных попыток входа:
$ sed -i -r -e "s/#Protocol 2/Protocol 2/" -e "s/#MaxAuthTries 6/MaxAuthTries 1/" /etc/ssh/sshd_config
# При необходимости отключаем selinux, так как в нашем случае он откровенно лишний
# Перезапускаем демона:
$ service sshd restart
# Проверяем, изменился ли порт:
$ ss -tnlp | grep ssh
LISTEN     0      128        *:7788        *:*     users:(("sshd",pid=1029,fd=3))
LISTEN     0      128       :::7788       :::*     users:(("sshd",pid=1029,fd=4))
# Открываем порт 7788:
$ firewall-cmd --zone=public --add-port=7788/tcp --permanent
$ firewall-cmd --reload
# Выходим и переподключаемся на **новый** порт
$ logout
```

Займемся отключением излишнего логирования, и чутка наведем красоту:

```bash
$ unset HISTFILE
$ echo 'unset HISTFILE' >> /etc/bashrc
# Ставим нано и выставляем его как редактор по умолчанию
$ yum -y install nano
$ echo 'export VISUAL=nano' >> /etc/bashrc
$ echo 'export EDITOR=nano' >> /etc/bashrc
# Опционально:
# $ service rsyslog stop && systemctl disable syslog
# $ service auditd stop && systemctl disable auditd
$ unlink /var/log/lastlog && ln -s /dev/null /var/log/lastlog
$ unlink /var/log/audit/audit.log && ln -s /dev/null /var/log/audit/audit.log
$ unlink /var/log/secure && ln -s /dev/null /var/log/secure
$ unlink /var/log/wtmp && ln -s /dev/null /var/log/wtmp
$ unlink /var/log/btmp && ln -s /dev/null /var/log/btmp
$ rm -f ~/.bash_history
# Красотульки
$ echo 'proxy-server' > /etc/hostname
$ hostname proxy-server
$ echo 'export PS1="\[$(tput bold)\]\[$(tput setaf 7)\][\[$(tput setaf 1)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 5)\]\h \[$(tput setaf 2)\]\w\[$(tput setaf 7)\]]\\$ \[$(tput sgr0)\]"' >> /etc/bashrc
# Ребутим, цепляемся по новой, проверяем логи на чистоту grep -rnw '/var' -e "%your_real_ap_addr%"
$ reboot
```

Теперь поставим прокси-сервер 3proxy (aka зараза-прокси) из исходников, и настроим его:

```bash
$ cd ~
$ yum -y install gcc
$ wget https://github.com/z3APA3A/3proxy/archive/3proxy-0.8.6.tar.gz
$ tar -xvzf 3proxy-*.gz
$ cd 3proxy-3proxy-*
$ sed -i '1s/^/#define ANONYMOUS 1\n/' ./src/proxy.h # Делает сервер полностью анонимным
$ make -f Makefile.Linux
$ mkdir -p /usr/local/etc/3proxy/bin
$ touch /usr/local/etc/3proxy/3proxy.pid
$ cp ./src/3proxy /usr/local/etc/3proxy/bin
$ cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
$ cp ./cfg/3proxy.cfg.sample /usr/local/etc/3proxy/3proxy.cfg
$ ln -s /usr/local/etc/3proxy/3proxy.cfg /etc/3proxy.cfg
$ chmod +x /etc/init.d/3proxy
# Настраиваем:
$ nano /etc/3proxy.cfg
```

```ini
daemon

pidfile /usr/local/etc/3proxy/3proxy.pid

nserver 8.8.4.4
nserver 8.8.8.8
nscache 65536

timeouts 1 5 30 60 180 1800 15 60
log /dev/null

auth none
maxconn 64
proxy -p13231 -n -a
socks -p14541 -n -a
```

Что означает, что прокси-сервер лог принудительно не пишет; для авторизации никаких паролей не просит; proxy работает на порту `13231`, socks на `14541`; сервер запущен с правами root _(да и насрать)_.

Запускаем его и ставим в автозагрузку:

```bash
$ service 3proxy start
$ systemctl enable 3proxy
```

И если всё хорошо - сносим исходники 3proxy как уже не нужные:

```bash
$ rm -Rf ~/3proxy-*
```

Дальше - настраиваем огненную стену:

```bash
# Открываем порт для http- и socks- прокси:
$ firewall-cmd --zone=public --add-port=13231/tcp --permanent
$ firewall-cmd --zone=public --add-port=14541/tcp --permanent
$ firewall-cmd --reload

# Блокируем ICMP трафик (echo-запросы) для того, чтоб наш сервер **не отвечал** на пинги:
# Проверяем состояние:
$ firewall-cmd --zone=public --query-icmp-block=echo-reply
$ firewall-cmd --zone=public --query-icmp-block=echo-request
# Блокируем:
$ firewall-cmd --zone=public --add-icmp-block=echo-reply --permanent
$ firewall-cmd --zone=public --add-icmp-block=echo-request --permanent
# Перечитаем правила:
$ firewall-cmd --reload
# И проверим теперь:
$ firewall-cmd --zone=public --query-icmp-block=echo-reply
$ firewall-cmd --zone=public --query-icmp-block=echo-request
```

И проверяем - всё должно работать. Шустренький и беспалевный прокси-сервер готов! Для проверки заходим через него, например, на 2ip.ru, и видим:

```bash
Откуда вы: Ukraine Украина, Киев
Ваш провайдер: ВестКолл Домашние сети
```

> Лучше будет ещё добавить в крон что-то вроде:
>
> ```bash
> 30 */3 * * * service 3proxy restart
> 0 */12 * * * reboot -f
> ```

Ну разве не профит, учитывая что физически серваки находятся в москве?
