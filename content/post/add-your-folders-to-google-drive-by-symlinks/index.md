---
title: Симлинки на «Рабочий стол» и «Мои документы» в облака
slug: add-your-folders-to-google-drive-by-symlinks
date: 2014-07-31T08:21:00+00:00
aliases: [/tnt/add-your-folders-to-google-drive-by-symlinks]
image: featured-image.jpg
categories: [tnt]
tags:
  - automate
  - cmd
  - google drive
  - script
  - symlink
  - windows
---

Согласись — было бы прикольно, если ты обладатель рабочего десктопа и нескольких мобильных гаджетов, и мог удобно расшаривать между ними файлы. В один момент пользуясь мобильным гаджетом и найдя что-то, что тебе в дальнейшем понадобится (картинка, изображение, документ, etc.) на десктопе — ты не просто делаешь закладку на объект и каким-то образом пересылаешь её, я просто сохраняешь его, и нужный файл появляется у тебя на рабочем столе десктопа.

<!--more-->

Аналогично и с гаджетами — чтоб расшарить файл ты просто помещаешь его в «Мои документы», и позже спокойно открываешь на гаджете. Стоит ли упоминать что это шикарная возможность иметь под рукой не только рабочие документы, но всё что тебе покажется необходимым?

## Что для этого необходимо?

1. Необходим установленный клиент [DropBox]-a или [GoogleDrive] или [Яндекс.Диска] на десктопе;
1. Аналогичный клиент на мобильных гаджетах;
1. Единожды запущенный [скрипт] **в директории необходимого сервиса** с десктопа под управлением Windows.

## Что в итоге?

По умолчанию мы получим 2 папки симлинка на “Мои документы” и “Рабочий стол”. Чтоб добавить что-то кроме них — скорректируй скрипт под свои нужды.

**[Скачать][GitHub]**

[DropBox]:https://www.dropbox.com/
[GoogleDrive]:http://www.google.ru/intl/ru/drive/download/
[Яндекс.Диска]:https://disk.yandex.ru/
[скрипт]:https://github.com/tarampampam/scripts/tree/master/win/create-symlinks
[Скачать]:https://raw.githubusercontent.com/tarampampam/scripts/master/win/create-symlinks/create-symlinks.cmd
[GitHub]:https://github.com/tarampampam/scripts/blob/master/win/create-symlinks/create-symlinks.cmd