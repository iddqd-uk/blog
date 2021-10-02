---
title: Поднимаем свой Jabber сервер
date: 2015-04-01T17:40:21+00:00
aliases:
  - /adm/install-xmpp-server-jabberd.html
featured_image: /images/posts/xmpp-wide.jpg
tags:
  - bash
  - centos
  - jabber
  - linux
  - mysql
  - openssl
  - ssl
  - xmpp
---

Да с игрищами и блудницами, да. Но перед тем как это делать - давай определимся - какой сервер мы будем ставить. Выбор предо мной, собственно, был не велик:

- [OpenFire](https://ru.wikipedia.org/wiki/Openfire) (Apache License 2.0) - написан на `Java` и большинство функций на нём делаются в бесплатной версии;
- [EJabberd](https://ru.wikipedia.org/wiki/Ejabberd) (GNU GPL) - написан на `Erlang`, модульный, есть веб-морда в комплекте, поддерживает кластеризацию;
- [jabberd2](https://ru.wikipedia.org/wiki/Jabberd2) (GNU GPL) - написан на `C`, тоже модульный, более компактный;

<!--more-->

Решено было разворачивать на.. **jabberd2** потому что:

1. Он написан на C и отличается малым потреблением ресурсов (два других кандидата в ней относятся в частности к памяти очень расточительно) плюс высокой производительностью (среднее потребление памяти v2.3.2 (x86_64) - sm/**6**Mb + c2s/**7**Mb);
1. Лишен лишних свистелок - он просто модульный xmpp сервер;
1. Он до сих пор поддерживается, да и сам по себе просто няшка.

### Установка

> Всю работу выполняем под рутом. Будьте внимательны и осторожны!

Цепляемся к нашему серверу на **CentOS 7** (установка на других дистрибутивах отличается, но в большинстве своем менеджером пакетов и некоторыми другими тонкостями), и [подключаем первым делом EPEL-репозиторий](http://www.rackspace.com/knowledge_center/article/install-epel-and-additional-repositories-on-centos-and-red-hat):

```bash
$ yum install epel-release
```

После чего ставим сам jabberd:

```bash
$ yum install jabberd
```

Вместе с собой он притащит в систему (только что поставленную, в нашем случае) ещё ~65 пакетов, для чего потребуется ~28Мб.

Отлично, теперь просто проверяем - запускается ли он у нас:

```bash
$ service jabberd start
$ cat /var/log/messages | grep jabberd
```

И если вывод (крайние строки) похож на:

```bash
Apr  1 11:22:33 localhost jabberd/sm[11987]: sm ready for sessions
Apr  1 11:22:33 localhost jabberd/s2s[11990]: [0.0.0.0, port=5269] listening for connections
Apr  1 11:22:33 localhost jabberd/s2s[11990]: ready for connections
Apr  1 11:22:33 localhost jabberd/c2s[11989]: [0.0.0.0, port=5222] listening for connections
Apr  1 11:22:33 localhost jabberd/c2s[11989]: ready for connections
```

Без каких-либо летально/фатальных сообщений - значит всё у нас хорошо.

### Настройка

Остается дело за малым - настроить его. Давай теперь определимся с тем, какой он в итоге должен иметь вид, тезисно:

- Имя сервера должно иметь вид `xmpp.domain.ltd`;
- Хранение информации о пользователях в mysql базе (это и удобное администрирование, и при необходимости - легко делается веб-морда для регистрации пользователей, к примеру);
- Открытая регистрация для пользователей (при заходе на наш сервер человек указывает желаемый ник, нажимает в своем же клиенте "Зарегистрироваться", профит);
- Логи переписки юзверей не ведем (по умолчанию), логи работы демонов - пишем в отдельный файл;
- Работа как без указания шифрования в настройках (SSL/TSL), так и с шифрованием;
- Транспорты и всё что с ними связано - оставим на потом.

#### Настройка DNS

Для того, чтоб при запросе `xmpp.domain.ltd` запросы попадали на наш сервер, где стоит jabberd - необходимо в DNS зоне `domain.ltd` добавить запись типа `A` со значениями хост - `xmpp`, значение - `Ip.Адреса.Нашего.Сервера`. Для сервиса `pdd.yandex.ru` это может выглядеть так:

![screenshot](https://hsto.org/files/ad0/573/f8d/ad0573f8d6404910b87c11e96cc0ea08.png)

Более того, так же есть смысл добавить следующие записи:

- `_xmpp-client._tcp.xmpp` типа `SRV` с весом `` и портом `5222` со значением `xmpp.domain.ltd.` и приоритетом `20`
- `_xmpp-server._tcp.xmpp` типа `SRV` с весом `` и портом `5347` со значением `xmpp.domain.ltd.` и приоритетом `20`

![screenshot](https://hsto.org/files/4bd/dd3/41b/4bddd341be264e8a9dd0f2b9bc03fe21.png)

Проверить работоспособность DNS очень просто - достаточно запустить `ping` домена `xmpp.domain.ltd` и убедиться что ответы приходят, и приходят с ip `11.22.33.44`.

#### Ставим MySQL (maria-db)

Машка ставится легко и не принужденно:

```bash
$ yum install mariadb-server
$ service mariadb start
```

Если всё запустилось без ошибок - ставим Машку в автозагрузку:

```bash
$ chkconfig mariadb on
```

После чего мы заходим в БД и выполняем предварительную настройку:

```bash
$ mysql
mysql> DROP DATABASE test;
mysql> USE mysql;
mysql> UPDATE user SET Password=PASSWORD('MyMysqlPassword') WHERE user='root';
mysql> FLUSH PRIVILEGES;
mysql> quit
```

Теперь у нас для mysql юзера под именем `root` установлен пароль `MyMysqlPassword`.

Так же есть смысл немного поправить настройки (`/etc/my.cnf`) доведя их, например, до следующего вида:

```ini
[mysqld]
user = mysql
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
key_buffer = 16M
max_allowed_packet = 4M
table_cache = 32
sort_buffer_size = 2M
read_buffer_size = 4M
read_rnd_buffer_size = 2M
net_buffer_length = 20K
thread_stack = 640K
tmp_table_size = 16M
query_cache_limit = 2M
query_cache_size = 16M
max_connections = 64
max_user_connections = 8
max_delayed_threads = 6
skip-networking
skip-federated
skip-blackhole
skip-archive
skip-external-locking

[mysqldump]
quick
max_allowed_packet = 16M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d
```

И перезапустить демона:

```bash
$ service mariadb restart
```

Теперь она будет потреблять памяти поменьше, но эти настройки актуальны лишь для мало нагруженных ресурсов.

#### Готовим MySQL к подключению jabberd

Чтоб jabberd смог работать с БД, необходимо её подготовить. Сперва необходимо зайти в консоль mysql:

```bash
$ mysql -u root -p
Enter password: [MyMysqlPassword]
```

И запустить скрипт создания таблицы (если что, он ещё [есть на GitHub](https://github.com/jabberd2/jabberd2/blob/master/tools/db-setup.mysql)):

```bash
MariaDB [(none)]> <strong>\. /usr/share/jabberd/db-setup.mysql</strong>
...
Query OK, 1 row affected (0.00 sec)
Database changed
...
Query OK, 0 rows affected (0.01 sec)

MariaDB [jabberd2]> <strong>show tables;</strong>
+--------------------+
| Tables_in_jabberd2 |
+--------------------+
| active             |
| authreg            |
| logout             |
| motd-message       |
| motd-times         |
| privacy-default    |
| privacy-items      |
| private            |
| queue              |
| roster-groups      |
| roster-items       |
| status             |
| vacation-settings  |
| vcard              |
+--------------------+
14 rows in set (0.00 sec)
```

И создаем mysql-пользователя с именем `jabberd2` и паролем `MyJabberdPassword`, предоставляя ему права на чуть ранее созданную бд:

```bash
MariaDB [jabberd2]> <strong>GRANT select,insert,delete,update ON jabberd2.* to jabberd2@localhost IDENTIFIED by '<u>MyJabberdPassword</u>';</strong>
Query OK, 0 rows affected (0.00 sec)

MariaDB [jabberd2]> <strong>select host, user, password from mysql.user;</strong>
+-----------------------+----------+-------------------------------------------+
| host                  | user     | password                                  |
+-----------------------+----------+-------------------------------------------+
| ...                   | ...      | *...                                      |
| localhost             | jabberd2 | *C40AAB2BB6AD68D6732CEF7F121C0C38FFFB870F |
+-----------------------+----------+-------------------------------------------+
N rows in set (0.00 sec)

MariaDB [jabberd2]> <strong>quit</strong>
```

На этом моменте считаем что mysql у нас готов к тому, чтоб начать работу с jabberd. Переходим к его настройке.

#### Настраиваем jabberd

Конфигурационные файлы jabberd находятся по пути `/etc/jabberd/`, и имеют формат `xml`. Первым делом - сделаем резервную копию конфигов, которые будем изменять:

```bash
$ mkdir -p /etc/jabberd/dist.cfg/
$ cp /etc/jabberd/*.xml /etc/jabberd/dist.cfg/
```

А так же создаем лог-файл (в который мы будем писать лог, вместо `syslog`) и ставим на него права:

```bash
$ touch /var/log/jabberd.log
$ chown jabber:jabber /var/log/jabberd.log
$ chmod 640 /var/log/jabberd.log
```

> **Внимание!** Если у вас активна SELinux - то демон jabberd не сможет писать в лог файл. Необходимо или корректно настроить права доступа, или выключить SELinux, изменив в файле `/etc/sysconfig/selinux` строку `SELINUX=permissive`, `permissive` на `disabled`, после чего перезагрузить ОС.

И начнем с файла `sm.xml`, приведя следующие его части к виду:

```xml
<sm>
  <!-- ... -->
  <router>
    <!-- ... -->
    <pemfile>/etc/jabberd/server.pem</pemfile>
  </router>

  <log type='file'>
    <ident>jabberd/sm</ident>
    <file>/var/log/jabberd.log</file>
  </log>

  <local>
    <id>xmpp.domain.ltd</id>
  </local>

  <storage>
    <driver>mysql</driver>
    <mysql>
      <host>localhost</host>
      <port>3306</port>
      <dbname>jabberd2</dbname>
      <user>jabberd2</user>
      <pass>MyJabberdPassword</pass>
      <transactions/>
    </mysql>
  </storage>

  <aci>
    <acl type='all'>
      <jid>admin@xmpp.domain.ltd</jid>
    </acl>
  </aci>

  <!-- ... -->

  <user>
    <auto-create/>
    <template>
      <publish>
        <active-cache-ttl>60</active-cache-ttl>
        <override-names/>
      </publish>
      <roster>/etc/jabberd/templates/roster.xml</roster>
    </template>
  </user>
  <!-- ... -->
</sm>
```

> Согласно этому конфигу, jabber сервер в качестве ключа аутентификации использует файл `/etc/jabberd/server.pem`. Логи пишутся в файл `/var/log/jabberd.log`. Имя сервера `xmpp.domain.ltd`. Для хранения данных используем локальный mysql, имя БД `jabberd2`, пользователь `jabberd2` с паролем `MyJabberdPassword`. Аккаунт (JID) администратора `admin@xmpp.domain.ltd`. Пользователям разрешена регистрация (`<auto-create/>`), и вновь зарегистрированным пользователям в контакт-лист мы добавляем пользователей (JID-ы) описанных в файле `/etc/jabberd/templates/roster.xml`.
>
> **Внимание!** В приведенном примере отображены лишь те параметры, которые есть смысл изменить или добавить. Так как исходный конфиг отлично документирован - разобраться в нем не должно составить большого труда.

После внесения изменений мы можем проверить его, перезапустив демона и посмотрев логи на наличие ошибок, и `netstat` на наличие открытых портов `2843`, `2844` и `2845`:

```bash
$ service jabberd stop; echo> /var/log/jabberd.log; service jabberd start
$ cat /var/log/jabberd.log
...
Wed Apr  1 11:22:33 2015 [notice] sm ready for sessions
...

$ netstat -lptu
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
...
tcp        0      0 0.0.0.0:5347            0.0.0.0:*               LISTEN      2885/router
tcp        0      0 0.0.0.0:xmpp-client     0.0.0.0:*               LISTEN      2886/c2s
tcp        0      0 0.0.0.0:xmpp-server     0.0.0.0:*               LISTEN      2887/s2s.
...
```

> Данную процедуру есть смысл повторять после изменения каждого файла, дабы вовремя предпринять меры по исправлению возможных ошибок при конфигурации.

Приступаем к правке файла `c2s.xml`, который отвечает за настройки соединения client-2-server:

```xml
<c2s>
  <!-- ... -->
  <router>
    <!-- ... -->
    <pemfile>/etc/jabberd/server.pem</pemfile>
  </router>

  <log type='file'>
    <ident>jabberd/c2s</ident>
    <file>/var/log/jabberd.log</file>
  </log>

  <local>
    <id register-enable='true'
        realm='xmpp.domain.ltd'
        instructions='Welcome to jabber server! Enter your fucking username and password'
        pemfile='/etc/jabberd/server.pem'>xmpp.domain.ltd</id>
    <pemfile>/etc/jabberd/server.pem</pemfile>
  </local>

  <!-- ... -->

  <authreg>
    <!-- ... -->
    <module>mysql</module>

    <mechanisms>
      <traditional>
        <plain/>
        <!--
        <digest/>
        -->
      </traditional>
      <sasl>
        <plain/>
        <!--
        <digest-md5/>
        <anonymous/>
        <gssapi/>
        -->
      </sasl>
    </mechanisms>

    <ssl-mechanisms>
      <traditional>
        <plain/>
      </traditional>
      <sasl>
        <plain/>
        <external/>
      </sasl>
    </ssl-mechanisms>

    <mysql>
      <host>localhost</host>
      <port>3306</port>
      <dbname>jabberd2</dbname>
      <user>jabberd2</user>
      <pass>MyJabberdPassword</pass>
      <password_type>
        <plaintext/>
        <!--
        <crypt/>
        <a1hash/>
        -->
      </password_type>
    </mysql>
    <!-- ... -->
  </authreg>
  <!-- ... -->
</c2s>
```

> Согласно этому конфигу, jabberd в качестве ключа аутентификации использует всё тот же файл `/etc/jabberd/server.pem`. Логи этого модуля (c2s) тоже пишутся в файл `/var/log/jabberd.log`. В секции `<local>` разрешаем регистрацию пользователей, дважды указываем доменное имя сервера, приветственное при регистрации сообщение и путь к ключу.
> Остальные параметры в большинстве своем можно оставить в таком виде, в котором они есть по умолчанию. Пароли в базе храним на период запуска - в открытом виде _(Внимание - не безопасно! После запуска - перевести на решим шифрования)_. Для остальных значений в `<authreg>` указываем интуитивно-понятные параметры
>
> **Внимание!** Как и в предыдущем примере - отображены лишь те параметры, которые есть смысл изменить или добавить.

Настал черед файла `s2s.xml`, который отвечает за настройки соединения `server-2-server` (в данный момент использовать данный функционал не будем, но у нас он будет уже преднастроен):

```xml
<s2s>
  <router>
    <!-- ... -->
    <pemfile>/etc/jabberd/server.pem</pemfile>
  </router>

  <log type='file'>
    <ident>jabberd/s2s</ident>
    <file>/var/log/jabberd.log</file>
  </log>

  <!-- ... -->

  <check>
    <interval>60</interval>
    <queue>60</queue>
    <retry>300</retry>
    <idle>86400</idle>
    <keepalive>0</keepalive>
    <dnscache>300</dnscache>
  </check>
  <stats>
  </stats>

  <!-- ... -->
</s2s>
```

> **Внимание!** Ну, ты уже понял - отображены лишь те параметры, которые есть смысл изменить или добавить

И укажем ростер JID-ов, которых необходимо добавлять ко всем пользователям, которые только зарегистрировались (именно его мы указывали в `/etc/jabberd/sm.xml`):

```xml
<query xmlns='jabber:iq:roster'>
  <item name='Administrator' jid='admin@xmpp.domain.ltd' subscription='none'><group>Admins</group></item>
</query>
```

> Здесь пояснять ничего, думаю, нет смысла. Подробнее можно почитать [по этой ссылке](http://www.umgum.com/jabberd2-public-roster).

Если после перезапуска демона у нас ничего критичного в логах нет, и необходимые порты открыты - считаем что на этом шаге jabberd у нас корректно настроен и работает.

Можем попробовать зарегистрировать учетную запись на нашем сервере в любимом jabber-клиенте. Всё должно работать, включая TLS/SSL шифрование (но с сообщением что сертификат самоподписанный).

#### Автозапуск при старте системы

В нашей связке jabberd+mysql имеется одно слабое место - а именно запуск jabberd **перед** тем, как запустится mariadb. Я решил эту задачу довольно примитивно - созданием политкорректного скрипта `/etc/rc.d/init.d/jabberd` (взят оригинальный, и пути поправлены под CentOS), и запуск его с задержкой в 15 секунд из `/etc/rc.local` после старта системы.

```bash
#!/bin/bash
#
# Raymond 25DEC2003 support@bigriverinfotech.com
# /etc/rc.d/init.d/jabberd2
# init script for jabberd2 processes
# Tested under jabberd-2.0rc2 and Fedora 1.0 only
#
# processname: jabberd2
# description: jabberd2 is the next generation of the jabberd server
# chkconfig: 2345 85 15
#
if [ -f /etc/init.d/functions ]; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ]; then
        . /etc/rc.d/init.d/functions
else
        echo -e "\ajabberd2: unable to locate functions lib. Cannot continue."
        exit -1
fi
#
progs="router sm c2s s2s"
progsPath="/usr/bin"
confPath="/etc/jabberd"
pidPath="/var/lib/jabberd/pid"
statusCol="echo -ne \\033[60G"
statusColorOK="echo -ne \\033[1;32m"
statusColorFailed="echo -ne \\033[1;31m"
statusColorNormal="echo -ne \\033[0;39m"
retval=0
#
StatusOK ( ) {
        ${statusCol}
        echo -n "[  "
        ${statusColorOK}
        echo -n "OK"
        ${statusColorNormal}
        echo "  ]"
        return 0
}
#
StatusFailed ( ) {
        echo -ne "\a"
        ${statusCol}
        echo -n "["
        ${statusColorFailed}
        echo -n "FAILED"
        ${statusColorNormal}
        echo "]"
        return 0
}
#
ReqBins ( ) {
        for prog in ${progs}; do
                if [ ! -x ${progsPath}/${prog} ]; then
                        echo -n "jabberd2 binary [${prog}] not found."
                        StatusFailed
                        echo "Cannot continue."
                        return -1
                fi
        done
        return 0
}
#
ReqConfs ( ) {
        for prog in ${progs}; do
                if [ ! -f ${confPath}/${prog}.xml ]; then
                        echo -n "jabberd2 configuration [${prog}.xml] not found."
                        StatusFailed
                        echo "Cannot continue."
                        return -1
                fi
        done
        return 0
}
#
ReqDirs ( ) {
        if [ ! -d ${pidPath} ]; then
                echo -n "jabberd2 PID directory not found. Cannot continue."
                StatusFailed
                return -1
        fi
        return 0
}
#
Start ( ) {
        for req in ReqBins ReqConfs ReqDirs; do
                ${req}
                retval=$?
                [ ${retval} == 0 ] || return ${retval}
        done
        echo "Initializing jabberd2 processes ..."
        for prog in ${progs}; do
                if [ $( pidof -s ${prog} ) ]; then
                        echo -ne "\tprocess [${prog}] already running"
                        StatusFailed
                        sleep 1
                        continue
                fi
                echo -ne "\tStarting ${prog}: "
                if [ ${prog} == "router" ]; then
                        ports="5347"
                elif [ ${prog} == "c2s" ]; then
                        ports="5222 5223"
                elif [ ${prog} == "s2s" ]; then
                        ports="5269"
                else
                        ports=""
                fi
                for port in ${ports}; do
                        if [ $( netstat --numeric-ports --listening --protocol=inet |
                                        gawk '{ print $4 }' |
                                                gawk -F : '{ print $NF }' |
                                                        grep -c ${port}$ ) -ne "0" ]; then
                                StatusFailed
                                echo -e "\tPort ${port} is currently in use. Cannot continue"
                                echo -e "\tIs a Jabber 1.x server running?"
                                Stop
                                let retval=-1
                                break 2
                        fi
                done
                rm -f /var/lock/subsys/${prog}
                rm -f ${pidPath}/${prog}.pid
                args="-c ${confPath}/${prog}.xml"
                ${progsPath}/${prog} ${args} >/dev/null 2>&1 <&1 &
                retval=$?
                if [ ${retval} == 0 ]; then
                        StatusOK
                        touch /var/lock/subsys/${prog}
                else
                        StatusFailed
                        Stop
                        let retval=-1
                        break
                fi
                sleep 1
        done
        return ${retval}
}
#
Stop ( ) {
        echo "Terminating jabberd2 processes ..."
        for prog in ${progs}; do
                echo -ne "\tStopping ${prog}: "
                killproc ${prog}
                retval=$?
                if [ ${retval} == 0 ]; then
                        rm -f /var/lock/subsys/${prog}
                        rm -f ${pidPath}/${prog}.pid
                fi
                echo
                sleep 1
        done
        return ${retval}
}
#
case "$1" in
        start)
                Start
                ;;
        stop)
                Stop
                ;;
        restart)
                Stop
                Start
                ;;
        condrestart)
                if [ -f /var/lock/subsys/${prog} ]; then
                        Stop
                        sleep 3
                        Start
                fi
                ;;
        *)
                echo "Usage: $0 {start|stop|restart|condrestart}"
                let retval=-1
esac
exit ${retval}
#
# eof
```

```bash
$ chkconfig jabberd off
$ wget -O /etc/rc.d/init.d/jabberd http://goo.gl/VJo3uF
$ chmod +x /etc/rc.d/init.d/jabberd
$ /etc/rc.d/init.d/jabberd restart
Restarting jabberd (via systemctl):                        [  OK  ]
```

И добавляем следующую запись в `/etc/rc.d/rc.local`:

```bash
## jabberd DOES NOT STARTS at autorun while mysql is NOT started!
## sleep must be executed!
if [ -x /etc/rc.d/init.d/jabberd ]; then
  (sleep 15; /etc/rc.d/init.d/jabberd restart);
fi;
```

И так же для "активации" обработки этого файла сделаем его исполняемым:

```bash
$ chmod +x /etc/rc.d/rc.local
```

После чего перезапускаем сервер целиком, и повторяем проверку на отсутствие ошибок в `/var/log/jabberd.log`, `/var/log/messages` и наличие открытых портов.

#### Получаем доверенный сертификат

Всё хорошо - клиенты у нас подсоединяются, TSL/SSL работает, SRV записи в DNS имеются, пользователи успешно регистрируются, системные логи - пишутся, и после перезапуска сервера - демоны поднимаются и работают как и задумывалось.

Но у нас постоянно появляется окно о самоподписанном сертификате в клиенте при первом подключении. Для того чтоб этого избежать мы можем получить бесплатный SSL сертификат на [startssl.com](https://www.startssl.com/) и использовать именно его.

- Регистрируемся на [startssl.com](https://www.startssl.com/?app=11) ![screenshot](https://hsto.org/files/434/bec/97f/434bec97fd7c418092cde0ab01ceaaa9.png)
- Подтверждаем [право владения доменом](https://www.startssl.com/?app=12) ![screenshot](https://hsto.org/files/51e/bfe/2e7/51ebfe2e7b8e4be792a8822e420a863e.png)
- Запрашиваем "XMPP (Jabber) SSL/TSL Certificate" ![screenshot](https://hsto.org/files/d04/840/705/d0484070505a4d20b96e33dfb74cfb20.png)
- Генерируем приватный ключ (введенный пароль обязательно сохранить) ![screenshot](https://hsto.org/files/ed4/b87/492/ed4b87492c264fd1aae9f6e314b61aad.png)
- Сохраняем полученный ключ как `ssl.key` ![screenshot](https://hsto.org/files/bcb/aec/c05/bcbaecc05d0a45cbbe345ad408da619c.png)
- Выбираем наш домен ![screenshot](https://hsto.org/files/c66/412/1e8/c664121e8fb64c849ab0ea8480901b7b.png)
- Указываем субдомен, на котором работает jabber сервер: ![screenshot](https://hsto.org/files/368/af0/332/368af03324564d5d80780500a375c618.png)
- Проверяем и подтверждаем: ![screenshot](https://hsto.org/files/0c1/a9a/85d/0c1a9a85d91f47388f4a780666d47a6a.png)
- Сохраняем полученный сертификат как `ssl.crt` ![screenshot](https://hsto.org/files/ee7/4c4/57a/ee74c457ab354b278235eb315a2d032b.png)
- Скачиваем ещё и корневой сертификат [sub.class1.server.ca.pem](https://www.startssl.com/certs/sub.class1.server.ca.pem)

После процедуры получения сертификата у нас будет 3 файла:

1. `ssl.key` - приватный ключ;
1. `ssl.crt` - сертификат;
1. `sub.class1.server.ca.pem` - корневой сертификат startssl.com;

Эти три файла переносим на сервер, переходим в директорию с ними и выполняем:

```bash
$ openssl rsa -in ssl.key -out ssl.key
$ cat ./ssl.crt ./ssl.key ./sub.class1.server.ca.pem >server.pem
$ chown jabber:jabber server.pem
$ chmod 640 server.pem
```

Не забываем о некоторых юансах:

- Лучше открыть итоговый сертификат любимым текстовым редактором и проверить чтоб секции не были нарушены;
- Итоговый сертификат должен заканчиваться одной пустой строкой;

Т.е. вид его должен быть в результате следующий:

```bash
-----BEGIN CERTIFICATE-----
ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ01
...
LMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNO
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ01
...
GHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXY
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIF2TCCA8GgAwIBAgIHFxU9nqs/vzANBgkqhkiG9w0BAQsFADB9MQswCQYDVQQG
...
gGpWAZ5J6dvtf0s+bA==
-----END CERTIFICATE-----
```

После этого делаем резервную копию файла `/etc/jabberd/server.pem`, и заменяем его получившимся новым сертификатом. Перезапускаем сервер, проверяем. Всё должно успешно заработать.

##### Полезные ссылки:

- [jabberd wiki](https://github.com/jabberd2/jabberd2/wiki)
- [Установка jabberd (icq jabber openbsd ssl)](http://www.opennet.ru/base/sys/jabber_openbsd.txt.html)
