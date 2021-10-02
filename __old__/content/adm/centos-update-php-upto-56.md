---
title: CentOS — обновляем php до 5.6
date: 2016-03-25T06:37:53+00:00
aliases:
  - /adm/centos-update-php-upto-56.html
featured_image: /images/posts/update-php-on-centos.jpg
tags:
  - bash
  - centos
  - php
---

Задался вопросом - при разработке web-приложений под какую версию `php` их "затачивать"? Ответ оказался проще некуда - достаточно посмотреть на [календарь релизов](http://php.net/supported-versions.php) и понять, что на данный момент поддерживаемой является версия `5.6.19`:

<!--more-->

![screenshot](https://hsto.org/webt/uf/eu/sl/ufeuslvrezgjfdxqcxf5ixs5y2e.png)

И ну никак не та (`5.4.16`), что встала из репозитория epel "по умолчанию". Для того чтоб исправить сложившуюся ситуацию выполним совсем не сложные действия, описанные ниже.

Первым делом заходим под рутом:

```bash
$ sudo su
```

После смотрим какие php пакеты у нас стоят:

```bash
$ yum list installed | grep php
php.x86_64                              5.4.16-36.el7_1                @updates
php-bcmath.x86_64                       5.4.16-36.el7_1                @updates
php-cli.x86_64                          5.4.16-36.el7_1                @updates
php-common.x86_64                       5.4.16-36.el7_1                @updates
php-devel.x86_64                        5.4.16-36.el7_1                @updates
php-fpm.x86_64                          5.4.16-36.el7_1                @updates
php-gd.x86_64                           5.4.16-36.el7_1                @updates
php-mbstring.x86_64                     5.4.16-36.el7_1                @updates
php-mcrypt.x86_64                       5.4.16-3.el7                   @epel
php-mysql.x86_64                        5.4.16-36.el7_1                @updates
php-pdo.x86_64                          5.4.16-36.el7_1                @updates
php-pear.noarch                         1:1.9.4-21.el7                 @base
php-process.x86_64                      5.4.16-36.el7_1                @updates
php-xml.x86_64                          5.4.16-36.el7_1                @updates
```

Отлично, сейчас у нас стоит версия 5.4 и нехитрый список пакетов. Список запоминаем и сносим к чертям всё что связано с php:

```bash
$ yum remove php-*
```

[Подключаем](http://devdocs.magento.com/guides/v2.0/install-gde/prereq/php-centos.html#instgde-prereq-php56-install-centos) epel и webtalic репозитории:

```bash
$ rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
$ rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
```

Проверяем на всякий случай:

```bash
$ php -v
-bash: php: command not found
```

Теперь ставим php 5.6 + opcache:

```bash
$ yum install php56w php56w-opcache
...
$ php -v
PHP 5.6.19 (cli) (built: Mar  4 2016 23:38:37)
Copyright (c) 1997-2016 The PHP Group
Zend Engine v2.6.0, Copyright (c) 1998-2016 Zend Technologies
    with Zend OPcache v7.0.6-dev, Copyright (c) 1999-2016, by Zend Technologies
```

Ага, красота, ставим остальные пакеты:

```bash
$ yum install php56w-mcrypt php56w-gd php56w-pdo php56w-pear php56w-gettext php56w-xml php56w-mysql php56w-intl php56w-mbstring
```

И не забываем перезапустить бэкэнд:

```bash
$ service httpd restart
```

#### Ссылки на другие статьи

* [PHP 5.6 on CentOS/RHEL 7.2 and 6.7 via Yum](https://webtatic.com/packages/php56/)
* [PHP 5.6 on CentOS](http://devdocs.magento.com/guides/v2.0/install-gde/prereq/php-centos.html#instgde-prereq-php56-install-centos)
* [How to Upgrade PHP 5.3 to PHP 5.6 on CentOS 6.7](https://www.zerostopbits.com/how-to-upgrade-php-5-3-to-php-5-6-on-centos-6-7/)
