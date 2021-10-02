---
title: Много анонимности не бывает — скрываем User-Agent
aliases:
  - /dev/random-hide-user-agent-for-google-chrome/
  - /dev/random-hide-user-agent-for-google-chrome.html
  - /dev/random-hide-user-agent-for-google-cgrome.html
date: 2014-08-05T03:03:00+00:00
featured_image: /images/posts/rnd-usr-agent-wide.jpg
tags:
  - anonymous
  - extension
  - google chrome
  - hide
  - useragent
---

> Данная статья является копией [публикации на хабре].

Очередной приступ паранойи был вполне обоснован — он наступил после прочтения [статьи о методах анонимности в сети], где автор на примере браузера FireFox рассказывал о потенциальных утечках идентификационной информации. И стало интересно — а на сколько озвученные решения применимы, скажем, к браузеру **Google Chrome**.

<!--more-->

Скрыть реальный IP — используем разные VPN сервера, отключить львиную долю отслеживающих скриптов — [Adblock Plus] и [Ghostery], убрать Referer — [не вопрос], что-то ещё забыли… Ах да — User-Agent — своеобразный &#171;отпечаток&#187;, по которому (в связке, скажем, с IP) легко идентифицировать пользователя. И с этим надо было что-то делать. Найденные решения лишь статично изменяли значение User-Agent, чего было явно недостаточно. Тогда и было решено написать плагин для скрытия реального User-Agent’a, а если быть точнее — подменять его на рандомный. Или почти рандомный.

Для нетерпеливых сразу: [исходники на GitHub] и расширение в [Google Webstore].

### Немного теории

Вообще, User-Agent (далее по тексту — **UA**) — штука нужная. Нужная в первую очередь для корректного отображения страниц, ведь нам всем известно — разные версии разных браузеров по разному рендерят странички, и заботливые web-программисты учитывают этот факт, выдавая нужным браузерам нужным скрипты и стили. Разнится поддержка доступных технологий «движками». Отсюда вытекает первое требование к итогу — возможность «имитировать» различные браузеры, и что самое важное — иметь возможность **выбора** между ними.

UA — это в первую очередь набор. Набор различных идентификаторов, по которым и происходит определение — какой браузер, какая операционная система, какой версии, и какое специфичное ПО (привет, IE) стоит у пользователя.

Почему именно IP и UA надо скрывать в первую очередь? А давайте посмотрим на лог пустого сайта-заглушки, на котором вообще ничего нет:

```bash
[meow@hosting /var/log]$ cat somesite.org.access_log | tail -3
10.12.11.254 - - [25/Jul/2014:15:51:16 +0700] "GET / HTTP/1.0" 200 5768 "-" "Mozilla/5.0 (compatible; MJ12bot/v1.4.5; http://www.majestic12.co.uk/bot.php?+)"
10.12.11.254 - - [25/Jul/2014:15:57:38 +0700] "GET / HTTP/1.0" 200 5768 "-" "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
10.12.11.254 - - [25/Jul/2014:19:19:25 +0700] "GET / HTTP/1.0" 200 5768 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0"
```

На сайте ничего нет, а я знаю о посетителе более чем достаточно. Всё потому что «логи знают всё» ©.

### Немного практики

Итак, решено — подставляем фейковый UA. Но как его сформировать? Я пошел по пути собирания с десятка UAкаждого интересующего браузера, и написания регулярки для каждого, которая будет генерировать **максимально правдоподобный** и в то же время а какой-то мере уникальный отпечаток. Хотите пример? Вот вам 10 UA браузера «IE 9», и среди них пять настоящих. Сможете отличить?

```bash
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; chromeframe/12.0.742.112)
Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 6.0; Win64; x64; Trident/5.0; .NET CLR 3.8.50799; Media Center PC 6.0; .NET4.0E)
Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 8.1; Trident/5.0; .NET4.0E; en-AU)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET CLR 2.0.50727; Media Center PC 6.0)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 8.0; WOW64; Trident/5.0; .NET CLR 2.7.40781; .NET4.0E; en-SG)
Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 8.0; Win64; x64; Trident/5.0; .NET4.0E; en)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 3.5.30729; .NET CLR 3.0.30729; .NET CLR 2.0.50727; Media Center PC 6.0)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 2.0.50727; SLCC2; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; Zune 4.0; Tablet PC 2.0; InfoPath.3; .NET4.0C; .NET4.0E)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 7.0; Trident/5.0; .NET CLR 2.2.50767; Zune 4.2; .NET4.0E)
Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0
```

Да, это возможно, но для это нужно анализировать. Анализировать, например, какие .net могут стоять на каких ОС, анализировать версии и сочетания, нюансы. Когда они теряются в куче — задача становиться мало тривиальной. Кому интересно как выглядят регулярки — добро [пожаловать по этой ссылке]. Дня генерации использовал [randexp.js] (за подсказку спасибо хабрачуваку под ником [barkalov]).

Вообще расширение успешно выдает себя за следующие браузеры:

* IE с 6 по 10;
* Chrome (Win / Mac / Linux);
* Firefox (Win / Mac / Linux);
* Safari (Win / Mac / Linux);
* Opera (Win / Mac / Linux);
* iPad и iPhone.

Что ещё интересного? **Автоматизация**. Отмечаешь галочками какие браузеры мы имитируем, ставишь галочку «Обновлять автоматически», указываешь интервал времени, и забываешь. Ничего лишнего.

![Screenshot](https://hsto.org/files/929/202/77b/92920277b5c24e46b7040893e4037a02.png)

Для любопытных — посмотрите в консоли «фоновую страницу» — там всё не плохо залогировано.

Открытые исходники. Если есть желание допилить под себя, всё что необходимо, это:

  1. Открыть ссылку расширения на гитхабе;
  2. Нажать «Download Zip» или склонировать;
  3. На странице расширений поставить чекбокс «Режим разработчика»;
  4. Нажать «Загрузить распакованное расширение…» и указать путь к распакованному архиву или клону;

Буду очень признателен конструктивной критике и предложениям.

### Ссылки

* **[Google Web Store]**
* **[GitHub]**

#### Будет полезно

* [Очень хорошее решение по локазизации расширения]
* [Исходники на GitHub]
* [Страница «randexp.js» на GitHub]
* [Викистатья о UserAgent]

[публикации на хабре]: https://habr.com/post/231107/
[статьи о методах анонимности в сети]: https://habr.com/post/203680/
[Adblock Plus]: https://chrome.google.com/webstore/detail/adblock-plus/cfhdojbkjhnklbpkdaibdccddilifddb
[Ghostery]: https://chrome.google.com/webstore/detail/ghostery/mlomiejdfkolichcflejclcbmpeaniij
[не вопрос]: https://chrome.google.com/webstore/detail/referer-control/hnkcfpcejkafcihlgbojoidoihckciin
[исходники на GitHub]: https://github.com/tarampampam/random-user-agent
[Google Webstore]: https://chrome.google.com/webstore/detail/random-hide-user-agent/einpaelgookohagofgnnkcfjbkkgepnp
[пожаловать по этой ссылке]: https://github.com/tarampampam/random-user-agent/blob/master/background.js
[randexp.js]: http://github.com/fent/randexp.js
[barkalov]: https://habr.com/users/barkalov/
[Google Web Store]: https://chrome.google.com/webstore/detail/random-hide-user-agent/einpaelgookohagofgnnkcfjbkkgepnp
[GitHub]: https://github.com/tarampampam/random-user-agent
[Очень хорошее решение по локазизации расширения]: http://codethug.com/2013/02/08/clean-markup-with-chrome-extension-i18n/
[Исходники на GitHub]: http://github.com/tarampampam/random-user-agent
[Страница «randexp.js» на GitHub]: http://github.com/fent/randexp.js
[Викистатья о UserAgent]: http://ru.wikipedia.org/wiki/User_Agent
