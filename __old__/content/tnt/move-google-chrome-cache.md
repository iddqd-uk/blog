---
title: Переносим кэш Google Chrome
aliases:
  - /tnt/move-google-chrome-cache.html
date: 2014-08-06T07:05:00+00:00
featured_image: /images/posts/chrome-wide.jpg
tags:
  - cache
  - cmd
  - google
  - google chrome
  - script
  - windows
---

Обладателям SSD + HDD винтов читать в первую очередь. Всем давно известно, что SSD винты чертовски шустрые, но, имеют ограниченный ресурс чтения/записи. В Сети есть херова куча советов, статей и программ по оптимизации работы ОС + ПО с ними, но мало кто пишет про небольшой нюанс касательно кэша хрома.

<!--more-->

Куда не плюнь, везде совет один &#8212; "Пропиши к линку браузера `--disk-cache-dir=%dir_name%`", и будет счастье. И да, и нет. Во первых &#8212; таким путем при открытии нескольких окон браузера с лаунчера Win7 мы получим ошибку синхронизации и входа в свой Google-аккаунт, а вторая копия будет писать в кэш по пути "по умолчанию", т.е. на системный (как правило SDD) винт, да и во-вторых профиль браузера не всегда будет подгружаться корректно. Но мы же знаем как отучить браузер считать себя умнее всех. В юниксах, кстати, всё выполняется аналогично, за исключением синтаксиса. Но, юниксоидов пока оставим в покое &#8212; подать сюда windows и симлинки:

```bash
cd C:\Users\{username}\AppData\Local\Google\Chrome
ren "User Data" "User_Data_old"
mkdir D:\temp\ChromeUserData
mklink /D "User Data" D:\temp\ChromeUserData
xcopy /E /H /Q /Y "User_Data_old" "D:\temp\ChromeUserData"
del /f /s /q User_Data_old
rmdir /s /q User_Data_old
```

А для совсем маленьких написал готовый скрипт, выполняющий всю работу. Скрипт железно работает под Win7 и выше, выводит подробную информацию, имеет настройки:

- [Скачать](https://raw.githubusercontent.com/tarampampam/scripts/master/win/move-google-chrome-cache/move-google-chrome-cache.cmd)
- [GitHub](https://github.com/tarampampam/scripts/blob/master/win/move-google-chrome-cache/move-google-chrome-cache.cmd)
