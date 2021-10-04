---
title: JavaScript — получаем статус Skype, VK и Jabber аккаунтов
date: 2015-04-28T15:15:04+00:00
aliases:
  - /dev/check-online-status-via-javascript.html
featured_image: /images/posts/js-wide.jpg
tags:
  - ajax
  - jabber
  - javascript
  - jquery
  - json
  - skype
  - status
  - vk
---

Вывод статуса аккаунта - довольно удобная хреновина которая позволяет, например, на странице контактов сразу указать - аккаунт в данный момент в сети, или же нет. Сейчас мы рассмотрим функции на Javascript (с использованием jQuery) для получения статуса аккаунта из трех наиболее популярных сервисов - Skype, VK.com и Jabber. Комментарии имеются лишь у первой по причине некоторой их однотипности - разобрав как работает одна - ты поймешь как работают и остальные. Демка так же имеется в конце этого поста.

<!--more-->

### Skype:

```javascript
// Source from: <https://gist.github.com/mattes/5253271>
// Необходимо чтоб в настройках аккаунта стояла галочка "Показывать мой статус" (или как то так)
var getSkypeStatus = function(user, callback) { // Функция принимает 2 параметра - логин Skype
                                                // и функцию, которая выполнится при получении
                                                // ответа-статуса
  if(!user) throw new Error("Missing skype user login");
  var query = "select * from skype.user.status where user=" + user + ";";
  $.getJSON("https://query.yahooapis.com/v1/public/yql?q=" + encodeURI(query +
  "&format=json&env=store://datatables.org/alltableswithkeys&callback=?"), function(data){
    console.log(data); // Закоментировать после отладки
    var isOnline = false; // Статус "по умолчанию"
    if(data.query.count > 0) { // Если ответ сервера не пустой
      switch (data.query.results.result.status) { // То проверяем его поле "status"
        // Offline (1), Online (2), Away (3), Do not disturb (3)
        case "2": case "3": isOnline = true; break;
      }
    }
    if(callback) return callback.call(null, isOnline); // Вызываем нашу функцию и передаем
                                                       // ей статус в качестве параметра
  });
};
```

### VK.com:

```javascript
// Найди свой ID на странице натроек ВК: <https://vk.com/settings>
var getVKstatus = function(userID, callback) {
    if(!userID) throw new Error("Missing vk user id");

    $.ajax({
      url: "https://api.vkontakte.ru/method/getProfiles?uids=" + parseInt(userID, 10) + "&fields=online",
      type : "GET", dataType: "jsonp", crossDomain: true,
      success: function(data){
        console.log(data);
        if(callback) return callback.call(null, data.response[0].online === 1);
      }
    });
  };
```

### Jabber:

```javascript
// Сперва необходимо добавить в свой контакт-лист аккаунт "mystatusbot@gmail.com", после
// чего от этого контакта придет сообщение с ссылкой на регистрацию в сервисе. Переходим
// по ней, вводим свой новый идентификатор, и именно _его_ уже передаем этой функцие
// для прверки статуса. Подробнее: <http://mystatus.im/>
var getJabberStatus = function(jabberID, callback) {
    if(!jabberID) throw new Error("Missing jabber username (registred in <mystatus.im>)");
    $.ajax({
      url: "http://mystatus.im/" + jabberID + ".json",
      type : "GET", dataType: "jsonp", crossDomain: true,
      success: function(data){
        console.log(data);
        var isOnline;
        switch (data.rawState) {
          case "online": case "away": isOnline = true; break;
          default: isOnline = false;
        }
        if(callback) return callback.call(null, isOnline);
      }
    });
  };
```
