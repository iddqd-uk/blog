---
title: Автоматическая сборка PHP-проектов с помощью PhiNG
date: 2016-02-16T15:36:49+00:00
aliases:
  - /etc/build-php-project-with-phing.html
featured_image: /images/posts/phing-wide.jpg
tags:
  - build
  - phing
  - php
  - windows
---

Что я подразумеваю под сборкой? Сборка - это процесс действий, которые выполняются над кодом проекта перед его деплоем. Она может включать в себя создание копии проекта, очистка директории с кэшем, минификация CSS и JS файлов, упаковка результата в один zip-архив. Так же возможно ещё и автоматическое развертывание проекта а удаленном сервере, но сегодня речь об этом идти не будет.

<!--more-->

Другими словами - это автоматизация однотипных и рутинных действий. А там где есть однотипные действия - там место автоматизации :) Сегодня мы рассмотрим на живом примере один из способов с применением PhiNG, причем всё будем делать с самого начала - скачаем исходники, интерпритатор (_в нашем случае это PHP_), и всё это дело настроим.

### Подготовка

Итак, мы работаем под Windows. Первым делом определимся с тем, как у нас всё располагается. Имеется директория `%project_name%`, в которой лежит директория `sources` с исходниками проекта (_пролинкована как домашняя директория на тестовом веб-сервере_), там же лежит `README.md` файл, и всё это располагается в Git-е (_всё всегда храним в Git-е_). Визуально это выглядит так:

```bash
[dir] %project_name%
  |- [dir] .git
  |- [dir] sources (исходники проекта)
  |- [file] .gitignore
  \- [file] README.md
```

В итоге нам необходимо чтоб была создана копия директории `sources`; над ней были произведены действия в виде минификации JS и CSS файлов, из PHP-файлов были удалены все комментарии; и в результате она упаковалась в файл `build_%timestamp%.zip`, удалив старую копию.

### Ставим PhiNG

В директории с проектом создадим ещё одну директорию, назвав её `build_tools`, в которую качаем [крайнюю версию PhiNG][1] ([GitHub](https://github.com/phingofficial/phing). Распаковываем из архива содержимое директории `phing-master` в директорию `.\build_tools\phing\`, после удалив всё, кроме директорий `bin`, `classes` и `etc`. Из директории `bin` копируем `phing.bat` в корневую директорию проекта, и называем его `build.cmd`.

### Ставим PHP

Теперь нам потребуется сам PHP. Берем его с [официального сайта](http://windows.php.net/download/), выбираем версию `5.5` под Windows. Распаковываем содержимое архива в директорию `.\build_tools\php-5\`, и удаляем всё, кроме файлов `php.exe`, `php.ini` и `php5.dll`. Всё что нам понадобится уже вкомпилено в сборку. В файле `php.ini` добавляем дефолтовую таймзону - сразу же после строки `[Date]` добавляем строку, например `date.timezone = "Asia/Yekaterinburg"`. Особого значения какая именно таймзона стоит - нет, но важно чтоб она была указана (_иначе PhiNG будет выдавать херову кучу warning-ов_). На этом считаем что PHP у нас готов.

### Переходим к настройке

В файле `build.cmd` (_что уже лежит в корне проекта_) необходимо указать где у нас располагается интерпритатор и PhiNG. Для этого редатируем две строки:

```bash
...
set DEFAULT_PHING_HOME=".\build_tools\phing"
...
set PHP_COMMAND=".\build_tools\php-5\php.exe"
...
```

Больше тут делать ничего нам более не придется. Остается создать файл конфигурации сборки - с корне проекта создадим файл `build.xml`, со следующим содержимым:

> **Важный момент!** Для минификации JS и CSS файлов я использую [Minify](https://github.com/matthiasmullie/minify), который пришлось "прикручивать" отдельно, так как в дефолтовой комплектации он просто не идет. Рассказ о том как его "прикручивал" достоин отдельного поста, но сейчас об этом речи не идет. Поэтому в конце статьи будут ссылки на уже готовую сборку PhiNG вместе с PHP в одном флаконе, с файлом конфигурации и запуском сборки.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- On-line help: <https://www.phing.info/docs/guide/stable/> -->
<project name="project_name" basedir="sources/" default="build">
  <property name="build_dir" value="../build/" override="false" />

  <tstamp>
    <format pattern="%Y_%m_%d__%H-%M-%S" property="build.time" />
  </tstamp>

  <target name="make_copy">
    <if>
      <available file="${build_dir}" type="dir" />
      <then>
        <echo>Remove old build directory</echo>
        <delete dir="${build_dir}" includeemptydirs="true" verbose="false" failonerror="true" />
      </then>
    </if>
    <echo>Make project copy</echo>
    <copy todir="${build_dir}" includeemptydirs="true" verbose="false" >
      <fileset dir=".">
        <include name="**/**" />
      </fileset>
    </copy>
  </target>

  <target name="make_clean" depends="make_copy">
    <echo>Clear cache</echo>
    <delete>
      <fileset dir="${build_dir}/cache/">
        <exclude name=".htaccess" />
      </fileset>
    </delete>
    <echo>Clear database directory</echo>
    <delete>
      <fileset dir="${build_dir}/db/">
        <exclude name=".htaccess" />
      </fileset>
    </delete>
    <echo>Clear logs directory</echo>
    <delete>
      <fileset dir="${build_dir}/log/">
        <exclude name=".htaccess" />
      </fileset>
    </delete>
  </target>

  <target name="min_js" depends="make_copy">
    <taskdef name="jsminify" classname="phing.tasks.JsMinifyTask" />
    <echo>Minifying JavaScript files</echo>
    <jsminify targetdir="${build_dir}" failOnError="true">
      <fileset dir="${build_dir}">
        <include name="**/*.js" />
        <exclude name="**/*.min.js" />
      </fileset>
    </jsminify>
  </target>

  <target name="min_css" depends="make_copy">
    <taskdef name="cssminify" classname="phing.tasks.CssMinifyTask" />
    <echo>Minifying CSS files</echo>
    <cssminify targetdir="${build_dir}" failOnError="true">
      <fileset dir="${build_dir}">
        <include name="**/*.css" />
        <exclude name="**/*.min.css" />
      </fileset>
    </cssminify>
  </target>

  <target name="protect_php" depends="make_copy">
    <echo>Protect PHP files</echo>
    <reflexive>
      <fileset dir="${build_dir}">
        <include name="**/*.php" />
      </fileset>
      <filterchain>
        <stripwhitespace />
        <tabtospaces tablength="1" />
      </filterchain>
    </reflexive>
  </target>

  <target name="pack" depends="make_copy">
    <echo>Pack to single archive</echo>
    <zip destfile="../build_${build.time}.zip">
      <fileset dir="${build_dir}">
        <include name="**/**" />
      </fileset>
    </zip>
  </target>

  <target name="remove_copy" depends="make_copy">
    <echo>Remove build directory</echo>
    <delete dir="${build_dir}" includeemptydirs="true" verbose="false" failonerror="false" />
  </target>

  <target name="build" depends="make_copy,make_clean,protect_php,min_js,min_css,pack,remove_copy">
    <echo>Build complete</echo>
  </target>
</project>
```

Чуть-чуть поясню конфигурацию:

- Первым делом мы объявляем имя проекта и указываем директорию где хранятся его исходники, так же указав дефолтовую цель: `build`. `<project name="project_name" basedir="sources/" default="build">`
- После мы добавили новое свойство `build_dir` со значением `../build/`, указав таким образом где у нас будет располагаться директория с билдом. Более того, к этому значению из конфига можно будет обращаться по `${build_dir}`. `<property name="build_dir" value="../build/" override="false" />`
- Секция с таймстампом мне кажется и так понятна - просто указываем формат временной метки, и после при необходимости к ней обращаемся по `${build.time}`
- Далее идут описания с "целями" (_читай в данном контекте - действиями_), тут всё должно быть более и менее понятно. В любой непонятной ситуации [читай документацию](https://www.phing.info/docs/guide/stable/)
- В конце мы указываем самую главную цель `build` (_указанную в самом начале_), в зависимостях которой перечисляем те, от которых она зависит (_читай - те действия, которые необходимо выполнить_)

Пояснять каждую цель не вижу особого смысла, т.к. [есть документация](https://www.phing.info/docs/guide/stable/), да и вообще они вполне интуитивны. Если будут какие-либо вопросы - спрашивай смело в комментариях - постараюсь на них ответить.

И остается самый ответственный момент - запустить сборку. Выполняем файл `build.cmd`:

![screenshot](https://hsto.org/webt/vl/pl/cf/vlplcfrqqvzp166enxyrmiftk74.png)

Как видим - сборка прошла без ошибок, и у нас в директории с проектом появился файл `build_%timestamp%.zip`, в котором все ресурсы нежно упакованы :) Как ты уже догадываешься - возможностей у PhiNG дохрена и больше - можно как делать и автоматическую загрузку итогового архива на удаленный сервер, так и производить массу иных операций. Но сейчас мы просто ознакомились с общим функционалом.

[1]:https://github.com/phingofficial/phing/archive/master.zip
