---
title: Настройка страниц ошибок для nginx
date: 2015-03-03T06:41:38+00:00
aliases:
  - /adm/customize-nginx-error-pages.html
featured_image: /images/posts/nginx-errorpages-wide.jpg
tags:
  - html
  - linux
  - nginx
  - service
---

При работе с web-ресурсом возникают ошибки, и причина их может быть совершенно различна - от опечатки в URL, до ошибок самого сервера. И если у нас внешним сервером является nginx - мы можем довольно удобно указать свое содержание, которое будет выводиться при той или иной ситуации. Во-первых это позволяет в какой-то мере замаскировать используемое ПО (т.к. определение по сигнатурам ответа становится невозможным); во-вторых - это визуальная кастомизация, которая положительно говорит о ресурсе в целом.

<!--more-->

#### Указание своих страниц ошибок

Для того, чтоб nginx вместо встроенных шаблонов отдавал нужный нам контент - существует следующая конструкция ([документация](http://nginx.org/ru/docs/http/ngx_http_core_module.html#error_page)):

```nginx
error_page 401 /401.html;
error_page 404 /404.html;
```

Которая нам говорит:

> В случае возникновения ошибки с кодом `401` вывести страницу `401.html`, которая находится в корне веб-ресурса, и т.д.

#### Страницы ошибок вне директории ресурса

Отлично, но что нам делать, если хотим чтоб страницы ошибок лежали отдельно от корневой директории веб-сервера? Нам на помощь приходит `location` ([документация](http://nginx.org/ru/docs/http/ngx_http_core_module.html#location)):

```nginx
set $errordocs /some/path/to/nginx-errordocs;

error_page 401 /401.html;
location = /401.html {
  root $errordocs;
}

error_page 404 /404.html;
location = /404.html {
  root $errordocs;
}
```

Которая говорит:

> Установим в переменную `$errordocs` значение `/some/path/to/nginx-errordocs`; в случае возникновения ошибки с кодом `401` вывести страницу `401.html`, которая находится в корне веб-ресурса; при запросе страницы `401.html` в корне веб-ресурса считать корнем веб-ресурса значение из `$errordocs`, и т.д. с описанными кодами ошибок

#### Глобальные страницы ошибок

А теперь ещё один момент - у нас может быть несколько хостов на одном сервере, и прописывать одни и те же настройки для каждого - дело не логичное. Тем более, что если произойдут какие-либо изменения - везде придется их обновлять.

К сожалению, я не нашел способа сделать их глобальными для всех "по умолчанию", но поступил следующим способом:

> Описываем все необходимые коды и страницы им соответствующие

```nginx
set $errordocs /some/path/to/nginx-errordocs;

error_page 401 /401.html;
location = /401.html {
  root $errordocs;
}

error_page 403 /403.html;
location = /403.html {
  root $errordocs;
}

error_page 404 /404.html;
location = /404.html {
  root $errordocs;
}

error_page 500 /500.html;
location = /500.html {
  root $errordocs;
}

error_page 502 /502.html;
location = /502.html {
  root $errordocs;
}

error_page 503 /503.html;
location = /503.html {
  root $errordocs;
}
```

Сохраняем в файл `/etc/nginx/errordocs_default.inc`. Во всех хостах, в секции `server {...}` дописываем одну строчку ([документация](http://nginx.org/ru/docs/ngx_core_module.html#include)):

```nginx
server {
  # ...
  include /etc/nginx/errordocs_default.inc;
  # ...
}
```

Перезапускаем nginx, проверяем.

#### Пример страницы ошибки

В качестве заготовки для содержимого страницы ошибки может быть следующий пример:

```html
<!DOCTYPE html>
<html><head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="robots" content="noindex, nofollow" />
  <title>Error 404</title>
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
  <link href="//fonts.googleapis.com/css?family=Oxygen:400,800" rel="stylesheet" type="text/css">
  <style type="text/css">
    html,body{margin:0;padding:0}
    body{overflow:hidden;text-align:center;background:#1a1a1a}
    .noselect{-webkit-touch-callout:none;-webkit-user-select:none;-khtml-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none}
    *{color:#eee;font-weight:400;font-family:Tahoma,Arial,Verdana;-webkit-transition:all .3s;-moz-transition:all .3s;-o-transition:all .3s;cursor:default;-webkit-font-smoothing:antialiased!important}
    .screenCenter{position:absolute;height:300px;width:450px;top:50%;left:50%;margin:-150px 0 0 -225px}
    h1,h4{font-family:Oxygen,Tahoma,Verdana,Arial;width:100%;padding:0;margin:0;text-align:center}
    h4{font-size:20px;position:absolute;top:110px;background:#1a1a1a;padding:10px 0;z-index:10}
    h1{font-size:220px;font-weight:800;text-shadow:0 0 32px #fff;color:transparent;opacity:.7;z-index:1}
    .screenCenter:hover h1{font-size:220px;font-weight:800;text-shadow:0 3px 3px rgba(0,0,0,1);color:#fff;opacity:1!important}
    .screenCenter:hover h4{opacity:0!important}
  </style>
</head><body>
  <div class="screenCenter noselect">
    <h4>File not found</h4>
    <h1>404</h1>
  </div>
</body></html>
```

Превью примера:

![screen](https://hsto.org/files/2f2/eef/c10/2f2eefc100fe4c918cad22b54f5efe72.gif)

Для создания других страниц будет достаточно изменить в примере все вхождения `404` на необходимый код, и поправить описание ошибки между `<h4>...</h4>`.
