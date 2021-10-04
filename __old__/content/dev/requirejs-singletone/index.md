---
title: Синглтон для RequireJS
date: 2017-02-18T05:19:58+00:00
aliases:
  - /dev/requirejs-singletone.html
tags:
  - javascript
  - oop
  - requirejs
---

Частенько при разработке приложения с использованием [requirejs](http://requirejs.org/) возникает необходимость в реализации [паттерна синглтона](https://ru.wikipedia.org/wiki/%D0%9E%D0%B4%D0%B8%D0%BD%D0%BE%D1%87%D0%BA%D0%B0_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)). И вот, испробовав пример его реализации что описан ниже заявляю - он имеет право на жизнь. Не без своих недостатков, разумеется, но в целом вполне применибельно:

<!--more-->

```javascript
'use strict';

define([], function () {

  /**
   * Singletone instance.
   *
   * @type {OurNewSingletone|null}
   */
  var instance = null;

  /**
   * OurNewSingletone object (as singletone).
   *
   * @returns {OurNewSingletone}
   */
  var OurNewSingletone = function () {

    /**
     * Initialize method.
     *
     * @returns {}
     */
    this.init = function () {
      // Make init
    };

    // Check instance exists
    if (instance !== null) {
      throw new Error('Cannot instantiate more than one instance, use .getInstance()');
    }

    // Execute initialize method
    this.init();
  };

  /**
   * Returns OurNewSingletone object instance.
   *
   * @returns {null|OurNewSingletone}
   */
  OurNewSingletone.__proto__.getInstance = function () {
    if (instance === null) {
      instance = new OurNewSingletone();
    }
    return instance;
  };

  // Return singletone instance
  return OurNewSingletone.getInstance();

});
```

И после, указывая наш модуль в зависимостях - мы получаем уже готовый к работе инстанс объекта _(один и тот же в разных модулях)_, что и требуется.
