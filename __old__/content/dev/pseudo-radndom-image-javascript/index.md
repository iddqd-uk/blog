---
title: "Псевдо-случайное изображение (на примере страницы 404-й ошибки)"
aliases:
  - /dev/pseudo-radndom-image-javascript.html
date: 2014-07-11T14:17:03Z
featured_image: /images/posts/rnd-404-image.jpg
tags:
- ajax
- habr
- javascript
- jquery
- json
- tumblr
- ui
---

> Данная статья является копией [публикации на хабре](https://habr.com/post/229449/).

Однажды автор этого поста работал над одним заказом по разработке простенько сайта и тогда появилась идея — придать всем страницам некой уникальности и запоминаемости — использовать уникальные фоновые текстуры или элементы дизайна (активно использовался parallax-scrolling). Так как в тот момент дедлайн был довольно близок, а идея — в зачаточном состоянии, было реализовано намного проще — простыми заготовками, но идея выброшена не была.

<!--more-->

Спустя некоторое время случайно наткнулся на мертвую ссылку, которая вела на [несуществующий](http://notexistsblog.tumblr.com/) Tumblr-блог, и страница ошибки сразу привлекла внимание. Обновив страничку фоновое изображение (в виде gif-анимации) сменилось — внимание ещё более усилилось. Почитав [исходники](http://assets.tumblr.com/assets/scripts/tumblr/error_page.js) стало понятно что все изображения «прописаны» статично, но это натолкнуло на другую идею, о которой вы узнаете под катом. Идея заключалась в следующем: «Почему бы нам в случае, когда необходимо оформить какую-либо страницу (в частности сервисную — _вход, выход, ошибка_), или просто получить тематическое изображение для оформления контента, не использовать псевдо-случайные изображения?» (возможно их использовать как элементы дизайна сайта). Семантически под «псевдо-случайными» я имею в виду изображения определенной тематики (или имеющие между собой какие-либо общие черты), но с течением времени результат «выпадения» был бы в той или иной степени уникальным. Возможные методы решения:

* Парсинг результатов поиска (google, yandex) по картинкам;
* Парсинг хостингов картинок, имеющие деление изображений по тегам или критериям;
* Инстаграм и сервисы иже с ним;
* Использовать средства блог-платформ, имеющих акцент на фото-контент.

Парсинг результатов поисковых запросов отпал по причинам встречающейся низкой релевантности, большого количества «мусора», а сами изображения хранятся черт знает где. Хостинг картинок — как-то не сложилось (может быть и зря) сразу. Инстаграм — низкое качество изображений (640х640 точек) и сложность в запросах для получения релевантных ответов. Так и остался крайний вариант — блог-платформы. Не скажу что выбор был мучительный, так как сам на Tumblr веду пару блогов и в курсе относительно статистики. В том числе — статистики постов:

![image](https://31.media.tumblr.com/98cd101ef5a1acd1738a47cf9f6e6b0a/tumblr_inline_n8jw9dTStI1r7zrwq.jpg) Плюсы данного решения:

* Изображения в тематических блогах придерживаются своего концепта в 9 из 10 случаев;
* При наличии корпоративного или личного блога на этом же сервисе изображения можно брать прямо из него, получается довольно прикольно;
* Нет необходимости беспокоиться об актуальности;
* Изображения находятся в открытом доступе;
* Tumblr отлично дружит с [ifttt](http://ifttt.com/).

Минусы:

* Если брать контент не у блога с устоявшимся форматом, есть вероятность получить изображение лысого мужика в наколках не соответствующее формату;

Теперь остается дело за малым — получить сами картинки. Хочется отдельно выразить благодарность разработчикам этой платформы, так как апи для получения и выборки контента очень прост и качественно реализован. Работу по получению и разбору данных было решено возложить на клиента (что без каких-либо сложностей переписывается на любой серверный язык). В итоге у меня получился следующий пример:

```html
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="description" content="404 | Page Not Found" />
    <title>404 | Page Not Found</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <link rel="shortcut icon" href="./blank-favicon.ico" />
    <link href="//fonts.googleapis.com/css?family=PT+Sans+Narrow&amp;subset=latin,cyrillic" rel="stylesheet" type="text/css" />
    <style type="text/css">
      *{margin:0;padding:0}
      html,body{min-height:100%;height:100%;min-width:100%;background-color:#000;overflow:hidden}
      body{position:fixed;font-family:'PT Sans Narrow',Helvetica,Arial,Verdana,sans-serif;visibility:visible;top:0;right:0;left:0;-webkit-font-smoothing:antialiased}
      #bg-fullscreen{position:absolute;-moz-opacity:0;opacity:0;top:0;left:0;width:100%;height:100%;background-size:cover;background-position:50% 50%;-webkit-transition:opacity 2s ease-in-out;-moz-transition:opacity 2s ease-in-out;-ms-transition:opacity 2s ease-in-out;-o-transition:opacity 2s ease-in-out;transition:opacity 2s ease-in-out;-webkit-filter:blur(3px);-moz-filter:blur(3px);-o-filter:blur(3px);-ms-filter:blur(3px);filter:blur(3px)}
      #bg-fullscreen.show{-moz-opacity:.9;opacity:.9}
      #content{position:absolute;top:0;left:0;width:100%;height:100%;text-align:center}
      #content *{color:#fff}
      #content h1{font-size:20em;text-shadow:0 0 42px rgba(0,0,0,1)}
      #content h3{font-size:5.4em;position:relative;top:-.9em;text-shadow:0 0 22px rgba(0,0,0,1);-moz-opacity:.9;opacity:.9}
      #content div.link{position:absolute;bottom:80px;text-align:center;width:100%}
      #content div a{display:inline-block;font-size:3em;position:relative;padding:0 30px 5px;background-color:#d63a0a;color:#fff;text-decoration:none;-webkit-box-shadow:0 0 30px 0 rgba(0,0,0,0.6);-moz-box-shadow:0 0 30px 0 rgba(0,0,0,0.6);box-shadow:0 0 30px 0 rgba(0,0,0,0.6)}
      #content a:hover{top:-1px}
      #content a:active{top:2px!important}
      @media only screen and (max-width: 1280px) {
      #content h1{font-size:13em}
      #content h3{font-size:3.8em}
      #content div a{font-size:2em}
      }
      @media only screen and (max-width: 479px) {
      #content h1{font-size:10em}
      #content h3{font-size:2.8em}
      #content div a{font-size:1.4em}
      }
    </style>
    <noscript>
        <style type="text/css">
            #bg-fullscreen {
                -moz-opacity: 0.9;
                opacity: 0.9;
                background-image: url('//habrastorage.org/files/7c1/dfc/c33/7c1dfcc3386347d0aa20b4f3cc1a410a.jpg');
            }
        </style>
    </noscript>
    <script type="text/javascript" src="//code.jquery.com/jquery-latest.min.js"></script>
    <script type="text/javascript">
        $(document).ready(function () {
            var imagesArray = [],
                debug = true;

            function getImagesFromTumblr(blogName, imgArr, imgCount, callback, makeOffset) {
                var offsetStep = 20,
                    makeOffset = typeof makeOffset !== 'undefined' ? makeOffset : 0,
                    imgCount = typeof imgCount !== 'undefined' ? imgCount : 5;
                $.ajax({
                    type: 'GET',
                    // https://www.tumblr.com/docs/en/api/v2
                    url: '//api.tumblr.com/v2/blog/' + blogName + '.tumblr.com/posts',
                    dataType: 'jsonp',
                    data: {
                        // https://www.tumblr.com/oauth/apps
                        api_key: 'P1M2xgqzN8Q5V9Oh1eMp2a6V2YceKV5Z7FvlPZlWgDXvPT6AMs',
                        offset: makeOffset

                    },
                    success: function (data) {
                        if (debug) console.log('Makeing request with offset = %d', makeOffset);
                        if (data.meta.status === 200) { // if answer is 'ok'
                            $.each(data.response.posts, function () {
                                if (this.type === 'photo') {
                                    $.each(this.photos, function () {
                                        var ext = this.original_size.url.split('.').pop(); // find image extension
                                        if (
                                            // check image for:
                                            (ext === 'jpg') // 1. type - 'jpg'
                                            && (this.original_size.width >= 640) // 2. minimal width
                                            //&& (this.original_size.width > this.original_size.height) // 2. horizontal
                                        ) {
                                            if (imgArr.length < imgCount) {
                                                imgArr.push(this);
                                            }
                                        }
                                    });
                                }
                            });
                        }
                        // if array not full..
                        if (imgArr.length < imgCount)
                        // ..make a recrussive run
                            getImagesFromTumblr(
                            blogName,
                            imgArr,
                            imgCount,
                            callback, ((makeOffset === 0) ? offsetStep : makeOffset + offsetStep)
                        )
                        else
                        if ($.isFunction(callback)) callback(true);

                    },
                    error: function () {
                        if (debug) console.error('Error try ajax request');
                        if ($.isFunction(callback)) callback(false);
                    }
                });
            }

            // 'womenexcellence' - girls, +18
            // 'life'            - black'n'white photos
            // 'weirdvintage'    - weird vintage
            // 'awesomepeoplehangingouttogether' - awesome people hanging out together
            // 'meiguiceserra'   - space planets

            if (debug) console.time('Getting Tumblr Images Data');
            getImagesFromTumblr('meiguiceserra', imagesArray, 15, function (noerror) {
                if (debug) console.timeEnd('Getting Tumblr Images Data');

                function getArrayItem(arr) {
                    return arr[Math.floor(Math.random() * arr.length)];
                }

                function preloadImg(url, callback) {
                    var pImg = new Image();
                    pImg.onload = function () {
                        if ($.isFunction(callback)) callback(true);
                    }
                    pImg.src = url;
                }

                if (debug) console.log(imagesArray);
                if (imagesArray.length > 0) {

                    var imageUrl = getArrayItem(imagesArray).original_size.url;
                    if (debug) console.log('Random image url: %s', imageUrl);

                    if (debug) console.time('Image downloading');
                    preloadImg(imageUrl, function () {
                        if (debug) console.timeEnd('Image downloading');
                        $('#bg-fullscreen').css({
                            'background-image': 'url(' + imageUrl + ')'
                        }).addClass('show');
                    });
                }
            });
        });
    </script>
</head>

<body>
    <div id="bg-fullscreen"></div>
    <div id="content">
        <h1>404</h1>
        <h3>Not found</h3>
        <div class="link">
            <a href="" class="home">&larr; Main page</a>
        </div>
    </div>
</body>

</html>
```

Алгоритм работы функции следующий:

1. Формируем и отправляем Ajax-запрос к [API Tumblr-a](https://www.tumblr.com/docs/en/api/v2#posts);
1. Проверяем статус ответа и проходимся по каждому посту;
1. Если это фото-пост, то проходимся по каждому изображению;
1. Если изображение нам подходит (например — тип, минимальный размер, соотношение сторон), то добавляем его в итоговый массив;
1. Если по завершению прохода нужное количество изображений не собрано — рекурсивно запускаемся снова, но с новым отступом.

Результат работы примера выглядит следующим образом (одно изображение — один показ):

![image](https://hsto.org/getpro/habr/post_images/669/11b/606/66911b606c9207dae96c016b9463a6cd.gif)

И несколько слов о том, в каком виде у нас возвращаемые данные:

![image](https://hsto.org/getpro/habr/post_images/4cb/9a2/924/4cb9a2924c62f4d4f790d5f701d49c46.jpg)

Плюсы данной реализации:

* Если захочется использовать gif-изображение — изменяем искомое расширение (строка ~178) и пересматриваем проверку размеров изображений;
* Чтобы изменить источник изображений — необходимо изменить один вызов функции;
* При отключенном JavaScript — выведем изображение из заготовки (см. `<noscript>… </noscript>`);
* Доступны различные размеры изображений;
* Работает даже в IE6 (при выключенном `debug` — режиме, строка ~153);
* Легко «допилить» под себя.

И минусы:

* В среднем получение и разбор данных (получалось 1..2 запроса, 10 изображений) во время тестов занимал порядка 0,4..1 секунды, что довольно долго;
* Необходимость таскать JQuery.

#### Эпилог

Данный метод может замечательно вписаться в небольшие сайты, портфолио, студии, блоги. Не нуждается в поддержке, легко интегрируется в готовые решения, не нагружает сервер. Вполне реально использовать в шаблонах для наполнения тестовым контентом (несколько строк на jQuery по замене ‘src’ у `<img />`). Буду рад, если кому-то помог, или навел на другую стоящую мысль.
