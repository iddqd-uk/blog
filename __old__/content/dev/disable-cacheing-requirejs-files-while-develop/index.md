---
title: Отключаем кэширование загружаемых RequireJS файлов при разработке
date: 2017-02-19T19:16:00+00:00
aliases:
  - /dev/disable-cacheing-requirejs-files-while-develop.html
featured_image: /images/posts/requirejs-wide.jpg
tags:
  - javascript
  - requirejs
---

Мне нравится [RequireJS](http://requirejs.org/). Нравятся принцип построения приложения с его использованием, то как он работает с зависимостями, его гибкость и настраиваемость. Но часто может возникать проблема при разработке на локале - кэширование ресурсов браузером _(файл подправил, а изменения не отображаются, так как файл берется из кэша)_.

Можно, конечно, открыть консоль и поставить флаг запрещающий кэширование, можно подправить конфиг web-демона так, чтоб он запрещал кэширование, а можно пойти другим путем - заставить requirejs добавлять рандомный параметр к своим запросам, таким образом заставляя браузер не брать файл из кэша.

<!--more-->

Для настройки requirejs я использую отдельный файл-конфигурацию, который загружается **перед** самой библиотекой, и содержит в себе как описания путей, зависимостей и прочие штуки - так и немного уличной магии.

Ниже будет пример его содержания в полном объеме, и думаю что комментарии тут будут излишне _(ссылка на [док](http://requirejs.org/docs/api.html#config))_. Такой код можно оставить работать и на продакшене без особых переживаний, но для разработки на локале есть как минимум одно очевидное ограничение - необходимо чтоб домен верхнего уровня был указан в массиве `local`, а так как для всех своих локальных проектов использую домен верхнего уровня `dev` - неудобств совсем не замечаю.

<!--more-->

```javascript
// @file ./js/config.js

'use strict';

/**
 * Requite.js configuration.
 *
 * @type {Object}
 */
var require = {
  paths: {
    app: 'js/app',
    // Components
    jquery: 'vendor/jquery/dist/jquery.min',
    bootstrap: 'vendor/bootstrap/dist/js/bootstrap.min'
  },
  shim: {
    bootstrap: {
      deps: ['jquery']
    }
  },
  deps: ['bootstrap'] // An array of dependencies to load
};


/**
 * Disable cache for requirejs resources while develop.
 *
 * @param   {Object} require
 * @returns {undefined}
 */
(function (require) {
  if (require !== false) {
    /**
     * Make test - is 'local' domain name?
     *
     * @returns {Boolean}
     */
    var isLocalDomain = function () {
      var host_name = document.location.hostname || window.location.host,
        local = ['dev', 'local', 'localhost', 'test', 'env'];
      if (typeof host_name === 'string') {
        var parts = host_name.split('.'), last = parts[parts.length - 1];
        if (parts.length === 1 || (!isNaN(parseFloat(last)) && isFinite(last))) {
          return true;
        } else {
          for (var i = 0, len = local.length; i < len; i++) {
            if (local[i] === last) {
              return true;
            }
          }
        }
      }
      return false;
    };
    /**
     * Append 'urlArgs' property.
     */
    require.urlArgs = isLocalDomain() ? (new Date()).getTime().toString() : null;
  }
})(typeof require === 'object' ? require : false);
```
