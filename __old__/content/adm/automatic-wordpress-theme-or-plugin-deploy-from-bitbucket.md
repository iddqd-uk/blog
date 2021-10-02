---
title: Автоматический деплой WordPress темы/плагина с Bitbucket
date: 2016-07-02T07:56:57+00:00
aliases:
  - /adm/automatic-wordpress-theme-or-plugin-deploy-from-bitbucket.html
featured_image: /images/posts/auto-wp-theme-plugin-deploy-from-bitbucket-wide.jpg
tags:
  - bitbucket
  - deploy
  - git
  - linux
  - ssh
  - wordpress
---

Времена, когда приходилось ручками заливать изменения файлов на prod-сервер - стремительно проходят, и на смену им приходят системы контроля версий и автоматизированный деплой. Ведь это чертовски удобно, когда ты один или с командой можешь работать над проектом, обкатывать изменения на локальном/тестовом сервере, и уже протестированный код отправлять на "боевой" сервер простым коммитом или слиянием. Ничего более не запуская, Карл!

Временами так же приходиться работать над проектами, построенными на (_пускай и по дизайну очень убогому_) WordPress, у которого очень низкий порог вхождения как у разработчиков, так и у конечных заказчиков (_с первого раза правильно прочитал "конечных заказчиков"?_).

<!--more-->

Почему бы не настроить автоматический деплой кода из приватного репозитория на Bitbucket.org (_или GitHub - не принципиально, но на нем нет халявных бесплатных репозиториев_) на "боевой" сервер под управлением этой CMS?

Давай сперва определимся с некоторыми моментами:

- В репозитории будет храниться только тема. Хранить в репозитории код самого WP и плагинов с wordpress.org смысла не имеет, так как авто-обновление (_надеюсь, включенное и настроенное по умолчанию_) делает это совершенно бессмысленным. Можно аналогичным способом деплоить и кастомные плагины;
- Конфиги для nginx так же в репозиторий не попадают. Да, можно было бы подключать их директивой `include /path/to/theme/config/*nginx*.conf`, но это и потенциальная возможность править от имени пользователя php конфиги nginx, и необходимость ему же дать право перезапускать его. Нельзя так делать;
- Использовать мы будем webhooks, а это ещё тот костыль по большому счету, так как не дает гарантии корректного выполнения кода на prod-сервере по причине отсутствия контроля состояния запроса;
- Синхронизацию БД придется делать любыми другими средствами, если они необходимы. О миграциях и прочих "вкусных" штучках задумываться есть смысл при разработке именно плагина, и реализовывать их придется самостоятельно;
- Придется разрешить php выполнять функцию `exec()`.

Но несмотря на озвученные выше очевидные минусы - это в дохрена раз удобнее, чем ничего. Работать будем под CentOS 7.

### Шаг #0 - Создание репозитория

Самостоятельно дерни актуальное состояние кода, создай репозиторий на Bitbucket.org, залей в его корень код темы (_плагина_).

### Шаг #1 - Настройка сервера

Всё делается из-под рута. Поставим пакеты:

```bash
$ yum -y install git
```

Посмотрим куда встал бинарник гита (_может понадобиться при настройке плагина для wp_):

```bash
$ whereis git
git: /usr/bin/git /usr/share/man/man1/git.1.gz
```

Проверим не запрещена ли php функция `exec` в `php.ini`:

```bash
$ cat /etc/php.ini | grep -e 'disable_functions' | grep -v -e '^;'
disable_functions = popen, exec, system, passthru, proc_open, shell_exec
```

И если как в моем случае запрещена, то разрешаем её удалением из этого списка (_да, это понижает безопасность, но без этого - никак_). Перезапускаем php-fpm (_или apache - что там у тебя?_):

```bash
$ service php-fpm restart
```

Посмотрим под чьим именем работает бэкэнд (_в моем случае в роли бэкэнда php-fpm, в твоем может стоять и apache - смотри его конфиг_):

```bash
$ cat /etc/php-fpm.d/* /etc/php-fpm.conf | grep -e 'user' | grep -v -e '^;'
user = php-fpm
```

Так же посмотрим где его домашний каталог:

```bash
$ getent passwd php-fpm | cut -f6 -d:
/var/lib/php-fpm
```

Создаем директорию для ssh-ключей и генерируем их для пользователя бэкэнда:

```bash
$ cd /var/lib/php-fpm
$ mkdir ./.ssh
$ chown php-fpm:php-fpm ./.ssh
$ sudo -u php-fpm ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/var/lib/php-fpm/.ssh/id_rsa): /var/lib/php-fpm/.ssh/id_rsa-bitbucket # Вводим
Enter passphrase (empty for no passphrase): # Ставим пустой пароль
Enter same passphrase again: # И снова просто нажимаем enter
Your identification has been saved in /var/lib/php-fpm/.ssh/id_rsa-bitbucket.
Your public key has been saved in /var/lib/php-fpm/.ssh/id_rsa-bitbucket.pub.
The key fingerprint is:
00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff php-fpm@server-name
The key randomart image is:
+--[ RSA 2048]----+
|         .       |
|      F + .      |
|     o.* * o     |
|      +oB + .    |
|     . oSo .     |
|    . .o*.       |
|     .+.+        |
|      .o         |
|      *o         |
+-----------------+
```

Выводим публичный ключ:

```bash
$ cat ./.ssh/id_rsa-bitbucket.pub
ssh-rsa AAAAB3Nza...keyishere...TmgDM3/7j1 php-fpm@server-name
```

И именно его добавляем в ключи развертывания репозитория на Bitbucket. Для этого переходим в браузере в репозиторий нашей темы &rarr; Настройки &rarr; Ключи развертывания &rarr; Добавить ключ. Добавляем именно как ключ развертывания (_а не ключ профиля_) для того, что бы избежать потенциальной вероятности его утечки и как следствия произвольного добавления кода в него.

Указываем использование сгенерированного ключа для хоста bitbucket.org:

```bash
$ nano /var/lib/php-fpm/.ssh/config
```

```ini
Host bitbucket.org
IdentityFile ~/.ssh/id_rsa-bitbucket
```

Выставляем права доступа:

```bash
$ chmod 0700 ./.ssh
$ chown -R php-fpm:php-fpm ./.ssh
$ chmod 0600 ./.ssh/id_rsa-bitbucket
```

После чего создаем тестовую директорию и пробуем в неё склонировать ветку "master" из репозитория:

```bash
$ mkdir /tmp/deploy-test
$ chmod 777 /tmp/deploy-test
$ sudo -u php-fpm git clone "git@bitbucket.org:%username%/%repo_name%.git" -b "master" "/tmp/deploy-test"
Cloning into '/tmp/deploy-test'...
The authenticity of host 'bitbucket.org (104.192.143.2)' cant be established.
RSA key fingerprint is 00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff.
Are you sure you want to continue connecting (yes/no)? yes # вводим ручками
Warning: Permanently added 'bitbucket.org,104.192.143.2' (RSA) to the list of known hosts.
remote: Counting objects: 305, done.
remote: Compressing objects: 100% (249/249), done.
remote: Total 305 (delta 49), reused 305 (delta 49)
Receiving objects: 100% (305/305), 836.84 KiB | 1.52 MiB/s, done.
Resolving deltas: 100% (49/49), done.
```

И проверяем содержимое клона, после чего удаляем тестовую директорию:

```bash
$ ls -l /tmp/deploy-test/
# ...
-rw-r--r-- 1 php-fpm php-fpm  1016 Jul  2 09:05 404.php
-rw-r--r-- 1 php-fpm php-fpm  1139 Jul  2 09:05 index.php
-rw-r--r-- 1 php-fpm php-fpm    42 Jul  2 09:05 style.css
# ...
$ rm -Rf /tmp/deploy-test/
```

На данном этапе мы можем считать что пользователь php-fpm у нас имеет как права для запуска git, так и авторизации на нашем приватном репозитории.

### Шаг #2 - Настройка WordPress

Будем использовать готовый плагин под названием **[Revisr](https://wordpress.org/plugins/revisr/)**, который вяло, но поддерживается. Можно, конечно, написать свой скрипт на любом удобном языке (_lua, perl для nginx, bash слушающий сокет или php_), но зачем?

Админка &rarr; Плагины &rarr; Добавить новый &rarr; Поиск плагинов &rarr; "Revisr" &rarr; установить и активировать. В главном меню появляется его "иконка" - жмякаем на неё, после чего начинается процесс установки. Выбираем "Yes, create a new repository":

![screenshot](https://hsto.org/webt/ek/x6/sm/ekx6smmih1b3o2suwhbhbuybjge.png)

Указываем что нам необходимо создать репозиторий только для одной конкретной темы (_с кастомным плагином действия аналогичные_):

![screenshot](https://hsto.org/webt/uy/hc/au/uyhcauoqwfgr1yuzxzid2qncmae.png)

И если всё хорошо, то видим:

![screenshot](https://hsto.org/webt/y1/lp/en/y1lpenw-1ptwi3gqr1j0yvxpw_q.png)

Делаем коммит всех изменений, и переходим в настройки "Revisr" &rarr; "Settings". Выставляем имя своего профиля на Bitbucket, почту, и отмечаем галочку о получении уведомлений по email.

Переходим в "Remote", и указываем имя ветки из которой брать код, ссылку на репозиторий вида `git@bitbucket.org:%username%/%repo_name%.git`, и отмечаем галочку "Automatically pull new commits?", после чего жмем на "Сохранить изменения".

URI адрес который появился после отметки крайней галочки вставляем на Bitbucket - переходим в браузере в репозиторий нашей темы &rarr; Настройки &rarr; Webhooks &rarr; Add webhook, выбираем триггер "Repository push", сохраняем.

### Шаг #3 - Проверяем

Не будем далеко ходить - создадим (_или изменим существующий_) файл `README.md` для нашей темы в корне репозитория, хоть средствами самого браузера, и запушим изменения. Откроем страницу "Webhooks" на Bitbucket и нажмем на "View requests" - запрос должен быть успешно обработан нашем веб-сервером (_вернуть код 200_), и после чего посмотрим любым способом на наличие изменений в файле `README.md` уже на самом prod-сервере.

Коммитим все изменения по новой (_что бы не раздражало уведомление об этом_), хотя нам плевать на состояние локального репозитория. Все изменения у нас односторонние - мы можем только забирать их, не забывай. Если есть необходимость (_очень не рекомендую_) править файлы на prod-сервере и обновлять их после этого в репозитории - перенеси ключ из ключей развертывания в ключи профиля - тогда будет работать в обе стороны.
