---
title: Индикатор загрузки страницы (css + pure js)
date: 2015-09-17T07:02:54+00:00
aliases:
  - /dev/page-loading-indicator-pure-js.html
featured_image: /images/posts/page-loading-wide.png
tags:
  - css
  - css3
  - html
  - javascript
  - loading
  - usability
---

Время загрузки страницы - самая унылая часть веб-серфинга :) До того момента, пока страница не загрузилась **до конца**, велика вероятность что она будет отображаться не так как мы задумывали - блоки могут "наезжать" друг на друга, текст - не отображаться (_пока не загрузились шрифты_), про корректную работу скриптов а анимации тоже зачастую можно забыть.

<!--more-->

Можно с этим явлением ничего не делать, но корректнее было бы скрыть до момента полной загрузки _критичного_ контента всё содержимое страницы, отобразив вместо него индикатор загрузки. По завершению же загрузки - скрыть индикатор, и показать пользователю уже загруженное и подготовленное браузером содержимое страницы. Именно этим мы сейчас и займемся.

Итак, каким же требованиям должен отвечать наш индикатор загрузки?

- Отсутствие растровых изображений;
- Старые браузеры - в топку, мы будем использовать современные `CSS3` методы;
- JavaScript поддерживается и включен по умолчанию более чем на 90% браузеров - не стесняемся его использовать;
- Минимализм по возможности во всем - это же индикатор загрузки, и именно он должен загрузиться и отрисоваться у клиента быстрее всего;
- И не забываем про адаптивность под мобильные гаджеты.

Давай посмотрим на довольно стандартную структуру HTML-страницы:

```html
<!doctype html>
<html lang="">
<head>
  <meta charset="utf-8" />
  <!--link rel="stylesheet" type="text/css" href="css/styles.css" /-->
  <title>...</title>
</head>
<body>

  <!-- Content goes here -->

  <!--script type="text/javascript" src="js/scripts.js"></script-->
</body>
</html>
```

Браузер получает html-код страницы и начинает по порядку загружать все внешние ресурсы в таком порядке, в каком как они указаны в теле страницы. В нашем импровизированном примере первым делом будут загружены и отрендерены 3 CSS-файла (`css/any.css`, `css/your.css` и `styles.css`), после чего - контент страницы, и по его завершению - JS скрипты (`js/any.js`, `js/your.js` и `js/scripts.js`).

Именно в каком порядке они у нас указаны - в таком порядке и будет происходить их загрузка (_исключениями являются скрипты с [указанием параметра](https://learn.javascript.ru/external-script) `async`/`defer`)_.

#### Разрабатываем индикатор загрузки

Для ускорения загрузки страницы код стилей и скрипта индикатора загрузки у нас будет указан прямо в теле html-страницы (_inline_). Основная его логика будет заключаться в следующем:

1. Описываем все связанные с ним стили в теге `<head>` inline-кодом;
1. Первым делом в теле `<body>` опишем структуру нашего индикатора загрузки, **перед** всем содержимым страницы;
1. После загрузки всех скриптов (_а так как они у нас загружаются последними, то считаем что содержимое страницы к этому моменту у нас уже загружено_) выполним код скрипта, который проверит статус загрузки документа и скроет индикатор загрузки тем самым показав содержимое страницы.

С точки зрения оформления мы будем использовать подобие прогресс-бара, стилизованного под Mac OS. Так как нам для работы необходим включенный JavaScript не забываем добавить тег `<noscript>...</noscript>` содержащий напоминание пользователю о его необходимости. Анимация его ни к чему не привязана, сделана просто "для красоты". Внешне результат у нас будет выглядеть так:

![screenshot](https://hsto.org/webt/bb/lj/ws/bbljwsnmkwtr6lrnuif3-_zkubk.png)

Код верстки:

```html
<div id="page_loading" class="light">
  <div class="loader"><div><div></div></div></div>
  <noscript>
    <div class="nojs">Please enable <strong>JavaScript</strong> and reload this page
      <p><a href="http://goo.gl/d5o4zF" target="_blank" rel="nofollow">How enable Javascript</a></p>
    </div>
  </noscript>
</div>
```

И стили:

```css
body.noscroll{
  min-height:100%;
  overflow:hidden
}

#page_loading{
  position: fixed;
  left: 0;
  top: 0;
  width: 100%;
  height: 100%;
  opacity: 1;
  z-index: 9999
}

.loader{
  position: absolute;
  top: 50%;
  left: 50%;
  height: 4px;
  width: 380px;
  margin: -2px 0 0 -190px
}

.loader>div{
  animation-duration: 3s;
  animation-name: loader_width;
  background-image: linear-gradient(to right,#4cd964,#5ac8fa,#007aff,#34aadc,#5856d6,#ff2d55);
  background-size: 380px 4px;
  height: 100%;
  position: relative
}

.loader>div>div{
  height: 64px;
  position: absolute;
  top: 100%;
  transform: skew(45deg);
  transform-origin: 0 0;
  width: 100%
}

@keyframes loader_width {
  0%,100%{transition-timing-function:cubic-bezier(1,0,0.65,0.85)} 0%{width:0} 100%{width:100%}
}

@-webkit-keyframes loader_width {
  0%,100%{transition-timing-function:cubic-bezier(1,0,0.65,0.85)} 0%{width:0} 100%{width:100%}
}

#page_loading.light{
  background-color: #f5f7f9;
  color: #555
}

#page_loading.light a{
  color: #666;
  border-color: #555
}

#page_loading.light a:before{
  background-color: #666
}

#page_loading.light .loader{
  background-color: #e5e9eb
}

#page_loading.light .loader>div>div{
  background-image: linear-gradient(to bottom,#eaecee,transparent)
}

#page_loading.dark{
  background-color: #272727;
  color: #e5e5e5
}

#page_loading.dark a{
  color: #fff;
  border-color: #ccc
}

#page_loading.dark a:before{
  background-color: #ddd
}

#page_loading.dark .loader{
  background-color: transparent
}

#page_loading.dark .loader>div>div{
  background-image: linear-gradient(to bottom,#292929,transparent)
}

#page_loading .nojs{
  position: absolute;
  width: 300px;
  top: 50%;
  left: 50%;
  margin-left: -150px;
  margin-top: 50px;
  text-align: center;
  font: 400 18px 'Open Sans','Helvetica Neue',Helvetica,Arial,sans-serif
}

#page_loading .nojs strong,#page_loading .nojs b{
  font-weight: 800
}

#page_loading .nojs a{
  font-size: 80%;
  text-decoration: none;
  border-style: dotted;
  border-width: 0 0 1px;
  position: relative
}

#page_loading .nojs a:before{
  content: '';
  position: absolute;
  width: 100%;
  height: 1px;
  bottom: -1px;
  left: 0;
  visibility: hidden;
  -webkit-transform: scaleX(0);
  transform: scaleX(0);
  -webkit-transition: all .3s ease-in-out 0;
  transition: all .3s ease-in-out 0
}

#page_loading .nojs a:hover:before{
  visibility: visible;
  -webkit-transform: scaleX(1);
  transform: scaleX(1)
}

@media all and (max-width: 414px) {
  .loader{width:320px; height:4px; margin:-2px 0 0 -160px}
  .loader>div{background-size: 320px 4px}
}
@media all and (max-width: 320px) {
  .loader{width:250px; height:4px; margin:-2px 0 0 -125px}
  .loader>div{background-size: 250px 4px}
}
```

> Важная заметка - в теле примера реализованы два готовых "стиля" индикатора - темный, и светлый. Применяются они путем указания класса `dark` или `light` соответственно к тегу `div#page_loading`. Так же после адаптации кода под ваш сайт/проект полученный CSS код лучше всего пропустить через [CSS compressor](http://csscompressor.com/) (_в случае необходимости его поправить там же его можно и "разжать"_).

Теперь перейдем к сокрытию индикатора. Для этого мы будем использовать небольшой js-скрипт **после** загрузки всех скриптов (_в самом конце страницы_). Всё что он делает - это с интервалом в 10 мс. проверяет `document.readyState`, и как только последний получит статус `complete`, то:

- Скрывает (_и удаляет из DOM_) индикатор загрузки;
- Удаляет класс `noscroll` у тега `<body />`;
- Останавливает работу проверяющего цикла;

Посмотрим на его исходник:

```javascript
// Hide loading overlay <div /> (with spinner) after page complete loading. After hiding,
//   <div /> will be removed, and for <body> removed css class 'noscroll'
var _loading_spinner=setInterval(function(){if(document.readyState==='complete'){
  var $page_loading = document.getElementById('page_loading'),
      $body = document.body || document.getElementsByTagName('body')[0],
      speed = 300, delay = 300;
  if((typeof $page_loading !== 'undefined') && ($page_loading != null)){
    setTimeout(function(){
      var transition = 'opacity ' + speed.toString() + 'ms ease',
          removeCssClass = function(obj, className){
            obj.className = obj.className.replace(className, '').replace('  ', ' ');
          };
      ['-webkit-transition','-moz-transition','transition'].forEach(function(prefix){
        $page_loading.style[prefix] = transition;
      });
      $page_loading.style['opacity'] = '0';
      $page_loading.style['filter']  = 'alpha(opacity=0)';
      removeCssClass($body, 'noscroll');
      setTimeout(function(){
        $page_loading.parentNode.removeChild($page_loading);
      }, speed + 10);
    }, delay);
  }
  clearInterval(_loading_spinner);
}},10);
```

Думаю, теперь разработать свой индикатор загрузки страницы тебе будет несколько легче. Если возникнут какие-либо вопросы - можешь их задавать в комментариях ниже.

#### Ссылки

- [Коллекция различных CSS индикаторов загрузки](http://codepen.io/collection/HtAne/)
- [Pace.js](http://github.hubspot.com/pace/docs/welcome/)
