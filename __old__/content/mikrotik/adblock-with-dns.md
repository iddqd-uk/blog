---
title: MikroTik — режем рекламу (ADBlock) с помощью DNS
date: 2015-07-22T08:19:59+00:00
aliases:
  - /mikrotik/adblock-with-dns.html
featured_image: /images/posts/mikrotik-adblock-wide.jpg
tags:
  - ad
  - bash
  - linux
  - mikrotik
  - script
---

> У данного поста имеется продолжение, позволяющее автоматизировать и значительно упростить весь процесс, описанный в этой записи. Располагается оно по [этой ссылке][1].

Прочитав [пост](https://habr.com/post/263081/) тов. [4aba](https://habr.com/users/4aba/) о том, как с помощью `dnsmasq` на прошитом роутере можно вполне успешно резать рекламные баннеры на всех устройствах, которые подключены к нашей точке доступа возник резонный вопрос - а можно ли реализовать аналогичное на маршрутизаторе **Mikrotik hAP lite**? Железка довольно таки достойная (_650MHz @ RAM 32 Mb_), но у нас нет полноценного linux-шелла на ней. Оказывается - можно, и результате было реализовано довольно простое, но эффективное решение.

<!--more-->

Пришлось пойти немного другим путем, а именно - прописать статичные DNS маршруты, которые при запросе "рекламного домена" переадресовывали наш запрос на `127.0.0.1`.

Списки "рекламных доменов" мы возьмем из открытых источников, таких как [http://pgl.yoyo.org/adservers/](http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&#038;showintro=0&#038;mimetype=plaintext) и [https://adaway.org/hosts.txt](https://adaway.org/hosts.txt) (_с легкостью можно изменить на любые другие_), приведем их в подобающий вид и оформим в виде скрипта для нашего Mikrotik-а, чтоб с помощью одной команды все их ему и "скормить".

### Получаем списки

Для выполнения этой задачи мы будем использовать linux-шелл. Скачиваем списки, и аккуратно складываем их под именами `./hosts_list.1`, `./hosts_list.2` и т.д.:

```bash
$ src=('http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext' 'https://adaway.org/hosts.txt'); i=0; for file in ${src[*]}; do i=$((i+1)); wget --no-check-certificate -O "./hosts_list.$i" "$file"; done;
```

### Приводим их в корректный для импорта формат

Грепаем всё что начинается на `127.0.0.1&nbsp;`, удаляем комментарии, оставляем только имена доменов, убираем дубликаты, убираем пустые строки, и оформляем каждый домен в виде команды для импорта:

```bash
$ in="./hosts_list.*" && out="./adblock_dns.rsc" && host='127.0.0.1'; echo "/ip dns static" > $out && grep '127.0.0.1 ' $in | grep -v '^#' | cut -d' ' -f 2 | sort -u | grep . | sed "s/^/add address=$host name=/" >> $out && rm -f $in; wc -l $out;
```

В итоге мы должны увидеть что то в духе `2803 ./adblock_dns.rsc`, для достоверности проверим содержимое:

```bash
$ head ./adblock_dns.rsc
/ip dns static
add address=127.0.0.1 name=101com.com
add address=127.0.0.1 name=101order.com
add address=127.0.0.1 name=123found.com
add address=127.0.0.1 name=123pagerank.com
add address=127.0.0.1 name=180hits.de
add address=127.0.0.1 name=180searchassistant.com
add address=127.0.0.1 name=1x1rank.com
add address=127.0.0.1 name=207.net
add address=127.0.0.1 name=247media.com
```

### Внедряем маршруты

Полученный файл `adblock_dns.rsc` заливаем по `ftp` на железку, и в её терминале выполняем:

```bash
# грохаем все имеющиеся записи в таблице статических DNS маршрутов
[admin@router] > /ip dns static remove [/ip dns static find]
# Импортируем загруженный файл
[admin@router] > /import adblock_dns.rsc
# Убираем за собой
[admin@router] > /file remove adblock_dns.rsc
```

Итого у нас 2802 статических маршрута на `loopback` в таблице (_эмпирически доказано что при импортировании ~5500 записей - железка встает почти колом_).

Остается лишь в настройках `DHCP` (`IP` &rarr; `DHCP Server` &rarr; `Networks` &rarr; `%default configuretion%` &rarr; `DNS Servers`) указать первым наш маршрутизатор, и опционально выполнить перезагрузку.

После ребута и тестового прогона на `Mikrotik hAP lite` спустя пару часов имеем `Free Memory 6.0 MiB`, `CPU Load 0..2%` (_показатели "до" замерить забыл, а сейчас уже лень_).

> Как автоматически выполнять аналогичную по смыслу операцию без использования дополнительной машины (только средствами самого микротика) по расписанию - ещё не придумал.

[1]:{{< ref "remove-a-lot-of-ad-using-mikrotik.md" >}}
