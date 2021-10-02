---
title: "Как удалить \"мусор\" от MacOS из файлошары"
aliases:
  - /tnt/clear-trash-by-macos-crontab.html
date: 2014-07-17T15:31:29Z
featured_image: /images/posts/tnt-wide.jpg
tags:
- bash
- cron
- linux
- macos
---

Пользователям этой ос должно быть хорошо известно, что во время работы мак-ось оставляет за собой довольно много различного “мусора”, в большей части являющегося просто кэшем изображений и прочего. В том числе весь этот хлам создается, когда владелец этой самой макоси заходит на файлошару, доступную для записи. Если вам необходимо от него избавиться, то вы можете смело создать небольшой скрипт и поставить его в cron. Ниже рассмотрим как это сделать в два простых шага.

<!--more-->

### 1. Создаем скрипт

```bash
$ cd ~ && nano ./rm_apple_cache.sh
```

И в него смело пишем:

```bash
#!/bin/bash

## @author    Paramtamtam
## @project   Remove most trash and some OSx .hidden cache files from
##            folders (recrussive)
## @copyright 2014
## @github    https://github.com/tarampampam/scripts/nix/
## @version   0.1.2
##
## @depends   bash, find, xargs

declare -a PathesArray=("/shares/Public/" "/shares/Public2/")

for Path in "${PathesArray[@]}"; do
  if \[ -d "$Path" \]; then
    find "$Path" \( \
      -name "._*" \
      -o -iname ".Apple*" \
      -o -iname ".Temporary*" \
      -o -iname ".apdisk" \
      -o -iname ".DS_Store" \
      -o -iname ".tickle" \
      -o -iname "thumbs.db" \
      -o -iname "desktop.ini" \
      -o -iname "autorun.inf" \
      -o -iname ".Bridge*" \
    \) -print0 | xargs -0 rm -rf
  fi
done;
```

Как видим, убиваем не только яблочный мусор, но и виндовый, опционально (`-name` — регистрозависимый поиск, а `-iname` — нет). Запускаем, смотрим чтоб не было ошибок, и мусор из шары удалился. Сохраняем, выставляем права на запуск:

```bash
$ chmod +x ~/rm_apple_cache.sh
```

### 2. Запускаем редактор заданий крона

Ставим задание в крон, которое, например, будет выполняться с 8 до 23 часов с интервалом раз в 4 часа:

```bash
$ crontab -e
0 8-23/4 * * * /root/rm_apple_cache.sh
```
