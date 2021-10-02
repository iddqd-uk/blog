---
title: iptables — заблокировать ip
date: 2015-02-19T07:32:00+00:00
aliases:
  - /adm/iptables-add-remove-rules.html
featured_image: /images/posts/iptables-wide.jpg
tags:
  - ban
  - iptables
  - linux
  - shell
  - unban
---

Рано или поздно встает задача - нужно для определенного ip закрыть доступ к ресурсу. Так же, если этот ip-адрес _серый_ (динамический), то лучше подвергнуть блокировке весь его сегмент. Сейчас рассмотрим на примере как это сделать при помощи **iptables**.

<!--more-->

Первым делом, мы берем ip будущей жертвы, и пробиваем по [who.is](http://who.is/), в выдаче выискивая строку вида:

```bash
% Note: this output has been filtered.
%       To receive output for a database update, use the "-B" flag.
% Information related to '111.111.111.0 - 111.111.111.255'
% Abuse contact for '111.111.111.0 - 111.111.111.255' is 'abuse@blabla.ltd'
```

Как раз `111.111.111.0 - 111.111.111.255` - то нам и нужно. Открываем [CIDR конвертер](http://ip2cidr.com/bulk-ip-to-cidr-converter.php), и вбиваем в него полученный диапазон:

```bash
111.111.111.0,111.111.111.255
```

Получая на выходе, например: `111.111.111.0/24`. Этот диапазон остается лишь добавить в iptables:

```bash
$ iptables -A INPUT -s 111.111.111.0/24 -j DROP
$ service iptables save
```

> Подразумеваю, что ты залогинен под рутом, и `iptables-services` у тебя уже установлены.

Теперь проверяем, точно ли встали правила:

```bash
$ service iptables restart
$ iptables -L
```

И в цепочке INPUT ищем:

```bash
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

...

DROP       all  --  111.111.111.0/24     anywhere
Chain FORWARD (policy ACCEPT)

...
```

Если оно имеет место быть - всё выполнено правильно, можно начать злобно потирать ладони :)

## Снимаем блокировку (удаляем правило из iptables)

Тут тоже нет ничего сложного. Для начала нам нужно выяснить - какой номер у нашего правила:

```bash
$ iptables -L INPUT --line-numbers
Chain INPUT (policy ACCEPT)
num  target     prot opt source               destination

...

6    DROP       all  --  111.111.111.0/24     anywhere

...
```

В нашем примере оно идет под номером **6**. Удаляем:

```bash
$ iptables -D INPUT 6
```

> Имей в виду, что если удаляешь несколько правил, например, следующих друг за другом - "5, 6, и 7", при удалении пятого - 6 и 7 сместятся вверх, и станут правилами под номерами 5 и 6. В данном вымышленном примере для удаления правил с 5 по 7 необходимо 3 раза подряд удалить правило под номером 5.

Теперь сохраняем и проверяем:

```bash
$ service iptables save
$ service iptables restart
$ iptables -L
```
