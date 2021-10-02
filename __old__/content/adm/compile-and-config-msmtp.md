---
title: Собираем и настраиваем msmtp
date: 2016-06-28T22:24:10+00:00
aliases:
  - /adm/compile-and-config-msmtp.html
featured_image: /images/posts/msmtp-wide.jpg
tags:
  - centos
  - linux
  - nginx
  - php
  - shell
---

[msmtp](http://msmtp.sourceforge.net/) - это простой консольный клиент для отправки сообщений электронной почты по протоколу SMTP.

Можно, конечно, пойти сложным путем и поставить полноценный почтовый сервер, но зачем? Нам ведь требуется просто позволить скриптам и демонам отправлять почту, а заморачиваться с DKIM, SPF, заголовками и прочим - крайне лень. Поэтому мы будем отправлять почту с помощью почтового ящика на yandex.ru, и поможет нам в этом приложение под названием [msmtp](http://msmtp.sourceforge.net/).

<!--more-->

> Важное замечание - в моем случае домен уже делегирован на яндекс, в DNS имеются все необходимые записи, почтовый ящик создан на странице pdd.yandex.ru, к нему прописаны алиасы вида `no-reply, noreply, donotreply, do-not-reply` для того, что бы была возможность иметь почтовый ящик с именем `info@domail.ru`, но успешно отправлять письма от имени, например, `no-reply@domail.ru`.

Единственное но - в репозиториях находится старая и бажная версия. Самый критичный для нас баг - это неизменяемое поле Sender, т.е. мы не можем указать имя (_или адрес? не помню_) отправителя. Смотрим что есть в репозиториях:

```bash
$ yum info msmtp
# ...
Name        : msmtp
Version     : 1.4.32
Release     : 1.el7
Size        : 120 k
# ...
```

Смотрим информацию о релизах на [официальном сайте](http://msmtp.sourceforge.net/news.html) - на момент написания этих строк это версия 1.6.5 (_уже без описанного выше бага_).

> Все манипуляции производились на "чистой" системе **CentOS 7.2**.

Скачаем исходники и соберем приложение ручками.

```bash
$ cd ~
$ yum install git
$ git clone git://git.code.sf.net/p/msmtp/code msmtp
$ cd msmtp
```

Ставим все необходимые для сборки пакеты:

```bash
$ yum install automake gcc gettext-devel gnutls-devel openssl-devel texinfo
```

Запускаем `autoreconf`:

```bash
$ autoreconf -i
autoreconf: configure.ac: AM_GNU_GETTEXT is used, but not AM_GNU_GETTEXT_VERSION
configure.ac:31: installing 'build-aux/config.guess'
configure.ac:31: installing 'build-aux/config.sub'
configure.ac:34: installing 'build-aux/install-sh'
configure.ac:34: installing 'build-aux/missing'
Makefile.am: installing './INSTALL'
doc/Makefile.am:3: installing 'build-aux/mdate-sh'
src/Makefile.am: installing 'build-aux/depcomp'
```

Конфигуряем:

```bash
$ ./configure
# ...
Install prefix ......... : /usr/local
TLS/SSL support ........ : yes (Library: GnuTLS) # <-- ВАЖНО
GNU SASL support ....... : no
IDN support ............ : no
NLS support ............ : yes
Libsecret support (GNOME): no
MacOS X Keychain support : no
```

И если предыдущая операция завершилась успешно (_наличие поддержки TLS/SSL для нас критично_), то собираем:

```bash
$ make
```

> Если во время сборки вылезла ошибка вида:
>
```bash
*** error: gettext infrastructure mismatch: using a Makefile.in.in from gettext version 0.19 but the autoconf macros are from gettext version 0.18
make[2]: *** [stamp-po] Error 1
make[2]: Leaving directory `/root/msmtp/po'
make[1]: *** [all-recursive] Error 1
make[1]: Leaving directory `/root/msmtp'
make: *** [all] Error 2
```
>
> То правим один файл:
>
```bash
$ nano ./po/Makefile.in.in
```
>
> Где заменяем строку `GETTEXT_MACRO_VERSION = 0.19` на `GETTEXT_MACRO_VERSION = 0.18`. После этого повторяем:
>
```bash
$ make
```

Выполняем установку **только** при успешной сборке (отсутствии каких-либо ошибок):

```bash
$ make install
```

Проверяем:

```bash
$ /usr/local/bin/msmtp --version
msmtp version 1.6.5
Platform: x86_64-unknown-linux-gnu
TLS/SSL library: GnuTLS # <-- ВАЖНО
Authentication library: built-in
Supported authentication methods:
plain external cram-md5 login
IDN support: disabled
NLS: enabled, LOCALEDIR is /usr/local/share/locale
Keyring support: none
System configuration file name: /usr/local/etc/msmtprc
User configuration file name: /root/.msmtprc

Copyright (C) 2016 Martin Lambers and others.
This is free software.  You may redistribute copies of it under the terms of
the GNU General Public License <http: //www.gnu.org/licenses/gpl.html>.
There is NO WARRANTY, to the extent permitted by law.</http:>
```

Создаем симлинки и заменяем "стандартный" sendmail (_убедись предварительно что он удален/не установлен_):

```bash
$ ln -s /usr/local/bin/msmtp /etc/alternatives/mta
$ ln -s /usr/local/bin/msmtp /usr/bin/msmtp
$ ln -s /etc/alternatives/mta /usr/lib/mail
$ ln -s /etc/alternatives/mta /usr/bin/mail
$ ln -s /etc/alternatives/mta /usr/sbin/mail
$ ln -s /etc/alternatives/mta /usr/lib/sendmail
$ ln -s /etc/alternatives/mta /usr/bin/sendmail
$ ln -s /etc/alternatives/mta /usr/sbin/sendmail
```

Создаем системный конфиг и симлинк на него в /etc:

```bash
$ touch /usr/local/etc/msmtprc
$ ln -s /usr/local/etc/msmtprc /etc/msmtprc
```

Выставляем права на файл и меняем группу файла для того, чтобы php-fpm (_и другие члены этой группы_) смогли читать его:

```bash
$ chmod 640 /usr/local/etc/msmtprc
$ chown :www-data /usr/local/etc/msmtprc
```

После этого переходим непосредственно к настройке:

```bash
$ nano /etc/msmtprc
```

```ini
defaults
tls on
auth on
tls_starttls on
tls_certcheck off
logfile /var/log/msmtp.log
timeout 20

account yandex
host smtp.yandex.ru
port 587
maildomain your_domain_name.ru
from no-reply@your_domain_name.ru
keepbcc on
user your_mailbox_name@your_domain_name.ru
password MAILBOX_PASSWORD

account default : yandex
```

И проверяем работу запуская как из консоли, так и из php-скрипта:

```bash
$ echo -e "\nSome test 1" | msmtp -d your_another_email@gmail.com
$ php -r "mail('your_another_email@gmail.com','Subject','Some test 2');"
```

Письма должны успешно приходить на `your_another_email@gmail.com`. Так же стоит проверить работу непосредственно из-под php-fpm, например, таким скриптом:

```php
<?php

  set_time_limit(15);
  error_reporting(E_ALL);
  ini_set('display_errors', 1);

  $result = mail('your_another_email@gmail.com', 'Subject', 'Some test 3');
  echo '<pre>'; var_dump($result); echo '</pre>';

  if ($result) {
    echo 'все путем';
  } else {
    echo 'что-то не так';
  }
```

И обратившись к нему из web. Если необходимо позволить какому-либо локальному пользователю так же из консоли отправлять письма, то необходимо создать новую группу, и добавить в неё необходимых пользователей, не забыв так же добавить в неё и `php-fpm`.

### Несколько почтовых ящиков и nginx

Так как на одном сервере могут располагаться несколько сайтов - наверняка возникнет потребность отправлять письма с разных сайтов от разных отправителей. Поясню - на одном сервере расположены сайты с доменными именами `site1.ru` и `site2.ru`. Соответственно, отправитель в исходящих письмах с сайта `site1.ru` должен быть вида `robot@site1.ru`, а в исходящих письмах с сайта `site2.ru` - вида `robot@site2.ru`. Для того что бы этого добиться нам необходимо прописать требуемые аккаунты в файле настроек msmtp:

```ini
defaults
tls on
auth on
tls_starttls on
tls_certcheck off
logfile /var/log/msmtp.log
timeout 20

account site1
host smtp.yandex.ru
port 587
maildomain site1.ru
from robot@site1.ru
user robot@site1.ru
password password_here

account site2
host smtp.yandex.ru
port 587
maildomain site2.ru
from robot@site2.ru
user robot@site2.ru
password password_here

account default : site1
```

Теперь по умолчанию письма будут уходить от имени аккаунта `site1`, так как он у нас указан как аккаунт по умолчанию. Для того что бы сообщить скриптам на сайте `site2.ru` использовать аккаунт `site2` необходимо добавить следующую строку в конфигурацию сервера `site2.ru` nginx:

```nginx
location ~ \.php$ {
    # ...
    fastcgi_param PHP_VALUE "sendmail_path = /usr/sbin/sendmail -t -i -a site2";
    # ...
  }
```

И после этого всё начнет работать так как надо.
