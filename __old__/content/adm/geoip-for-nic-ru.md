---
title: Установка mod_geoip на nic.ru, или как ограничить доступ к сайту «по странам»
date: 2014-08-09T10:51:00+00:00
aliases:
  - /adm/geoip-for-nic-ru.html
featured_image: /images/posts/geoip-rucenter-wide.jpg
tags:
  - access
  - apache
  - block
  - geoip
  - htaccess
  - linux
---

Есть некоторый ресурс, который хостится на площадке **nic.ru** с тарифным планом "302". Посещаемость у этого ресурса в один прекрасный момент возрасла на столько, что хостинг перестал справляться, и просто умирать. Причиной тому - мизерное количество памяти (**256Мб**) на самом дорогом тарифе хостинга. Переписка с поддержкой завершилась на их позиции "если Вам мало - покупайте что подороже, у нас как рас есть для вас отличное предложение" (внимание - ответ перефразирован, из-за повышенной злобы). Но у нас есть временно не решенный вопрос - перегрузки на сайте. Проанализировав логи с помощью [Apache Logs Viewer](http://www.apacheviewer.com/) было выяснено - львиная доля запросов поступает из-за границы, а ресурс предназначен изначально только для жителей РФ. Что делать?

<!--more-->

Первая мысль - рулить при помощью php запросы, благо есть ipgeobase.ru, есть maxmind.com - можно разгуляться, но.. Но php не может работать "прозрачно". Файлы на ресурсе раздавались по прямым ссылкам, без редиректов каких-либо, и очень важно было это сохранить. Более того, как говорилось выше - памяти у нас дефицит, а запросов от 3 до 10 в секунду - запускать для этого php или ещё что-то подобное - хреновая идея.. Было решено следующее - ставить **mod_geoip** для **Apache1.3** и при помощи правил в **.htaccess** разрулить кому давать доступ, а кому отказать. Сказано - сделано.

## Приступаем

```bash
[login@web** ~]$ cd ~
[login@web** ~]$ wget http://geolite.maxmind.com/download/geoip/api/mod_geoip/mod_geoip_1.3.4.tar.gz
[login@web** ~]$ tar -xzf mod_geoip_1.3.4.tar.gz
[login@web** ~]$ rm mod_geoip_1.3.4.tar.gz
[login@web** ~]$ mkdir geoip
[login@web** ~]$ cd geoip
[login@web** ~/geoip]$ wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP-1.4.5.tar.gz
[login@web** ~/geoip]$ tar -xzf GeoIP-1.4.5.tar.gz
[login@web** ~/geoip]$ rm GeoIP-1.4.5.tar.gz
[login@web** ~/geoip]$ cd GeoIP-1.4.5
[login@web** ~/geoip/GeoIP-1.4.5]$ ./configure --prefix=/home/{YourLogin}/geoip
[login@web** ~/geoip/GeoIP-1.4.5]$ make
[login@web** ~/geoip/GeoIP-1.4.5]$ make install
[login@web** ~/geoip/GeoIP-1.4.5]$ cd ../../mod_geoip_1.3.4/
[login@web** ~/mod_geoip_1.3.4]$ apxs -cia -I/home/{YourLogin}/geoip/include -L /home/{YourLogin}/geoip/lib -lGeoIP ./mod_geoip.c
[login@web** ~/mod_geoip_1.3.4]$ mkdir -p ~/geoip/httpd/
[login@web** ~/mod_geoip_1.3.4]$ cp mod_geoip.* ~/geoip/httpd/
```

На ошибки во время `apxs` смело забейте. Главное - чтоб в директории появилась скомпиленная либа `mod_geoip.so`.

Ещё нам нужен .dat файл самой базы IP, по которой то и происходит определение - откуда у нас посетитель. Я сделал так:

```bash
[login@web** ~]$ cd ~/geoip/
[login@web** ~/geoip]$ wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
[login@web** ~/geoip]$ gzip -d GeoIP.dat.gz
[login@web** ~/geoip]$ chmod 744 GeoIP.dat
[login@web** ~/geoip]$ ls
```

В итоге у нас по пути `~/geoip/GeoIP.dat` он и находится.

Итак, мы считаем, что на данный момент у нас есть директория `~/geoip/httpd/`, а в ней есть so и c файлы модуля. Переходим к настройке хостинга. Первым делом - врубаем ручной режим настроек в [панели управления](https://www.nic.ru/hcp/cgi-bin/gen_avd.pl?mItem=web_server&hitem=&page=), после - залезаем обратно в консоль и немного правим файл `~/etc/apache_1.3/httpd.conf`, дописывая в него следующее:

```apache
#LoadModule ...
LoadModule geoip_module /home/{YourLogin}/geoip/httpd/mod_geoip.so

#...

#AddModule ...
AddModule mod_geoip.c
<IfModule mod_geoip.c>
  <IfModule mod_realip.c>
    GeoIPEnable On
    GeoIPEnableUTF8 On
    GeoIPScanProxyHeaders On
    GeoIPOutput All
    GeoIPDBFile /home/{YourLogin}/geoip/GeoIP.dat
  </IfModule>
</IfModule>

```

Обрати **внимание** - для нормальной работы модуля за nginx обязательно нужен модуль `mod_realip`. После этого идем в панель, и перезапускаем виртуальный сервер (как корректно это сделать из консоли я так и не понял на данный момент). Если всё хорошо (на странице не появилось сообщение об ошибке) - то мы продолжаем. На это раз мы лезем уже в корневую директорию самого сайта, и создаем в ней простой файл `test.php` с классическим содержанием `<?php phpinfo(); ?>`. После того, как мы откроем его в браузере, ишем строку, содержащею `GEOIP_COUNTRY_CODE`. Если её нет - пишите в комментарии или на почту - помогу разобраться при возможности. Если есть - значит мы всё сделали правильно :)

Теперь остается дело за малым - само правило, ограничивающее доступ для запросов из определенных стран. Добавляем в `.htaccess` следующий код:

```apache
## Disable access for countries
## https://www.maxmind.com/ru/home
<IfModule mod_geoip.c>
  <IfModule mod_realip.c>
    GeoIPEnable On
    SetEnvIf GEOIP_COUNTRY_CODE (UZ|US|AE|UA|MD|LV|KG|KP|KZ|GE|CZ|CA|BG|BY|AZ|AM) DenyCountry
    Order allow,deny
    Deny from env=DenyCountry
    Allow from all
  </IfModule>
</IfModule>
```

Как мы видим из примера - мы запретили доступ для ряда стран по их коду, весь список можно одним глазком [глянуть здесь](http://countrycode.org/).

На этом всё, надеюсь вы нашли этот пост до того как окончательно сломали голову. Nic.ru такой nic.ru :)
