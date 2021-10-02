---
title: "Деплой на Docker Swarm"
slug: compose-deploy
date: 2018-10-15T13:35:50Z
featured_image: /images/posts/docker-in-clouds-wide.png
tags:
- linux
- deploy
- docker-compose
- docker
- devops
---

> Данный пост является переводом [части документации][source_doc], посвященной секции `deploy` в `docker-compose`

## `deploy`

> Начиная с [версии **3**][compose_v3].

Группа настроек, посвященная деплою и запуску сервисов. Указанные в данной группе настройки используются **только** при деплое на [swarm][swarm] используя [`docker stack deploy`][stack_deploy], и игнорируется при использовании команд `docker-compose up` и `docker-compose run`.

<!--more-->

```yaml
version: '3'

services:
  redis:
    image: redis:alpine
    deploy:
      replicas: 6
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
```

<!--more-->

Доступны следующие дополнительные опции:

### `endpoint_mode`

Используемый метод обнаружения ("service discovery") для внешних запросов от клиентов.

> Начиная с [версии **3.3**][compose_v3].

- `endpoint_mode: vip` - Докер присваивает сервису виртуальный IP адрес (VIP), который выступает в роли "внешнего" для получения доступа к сервису. Докер сам занимается маршрутизацией запросов между клиентом и доступным воркером (на котором крутится сервис), при этом клиент ничего не знает ни о количестве нод, ни о их IP и портах (используется по умолчанию).
- `endpoint_mode: dnsrr` - DNS "round-robin" (DNSRR) **не** использует одиночный виртуальный IP адрес. Докер устанавливает DNS записи для сервиса таким образом, что когда клиент его запрашивает - ему возвращается список из IP адресов, и клиент сам подключается к одному из них. DNS "round-robin" полезен в случаях использования своего собственного балансировщика нагрузки, или для гибридных Windows & Linux приложений.

```yaml
version: "3.3"

services:
  wordpress:
    image: wordpress
    ports:
      - "8080:80"
    networks:
      - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: vip

  mysql:
    image: mysql
    volumes:
       - db-data:/var/lib/mysql/data
    networks:
       - overlay
    deploy:
      mode: replicated
      replicas: 2
      endpoint_mode: dnsrr

volumes:
  db-data:

networks:
  overlay:
```

`endpoint_mode` так же можно использовать как флаг запуска при использовании консоли [`docker service create`][service_create]. Список всех связанных swarm-команд [доступен по этой ссылке][swarm_cli].

Если вы хотите узнать больше о "service discovery" и сетях в swarm-режиме, перейдите в [раздел настройки service discovery][network_overlay].

### `labels`

Установка ярлыков (labels) сервиса. Эти ярлыки присваиваются _только самому_ сервису, а _не_ какому-либо контейнеру этого сервиса.

```yaml
version: "3"

services:
  web:
    image: web
    deploy:
      labels:
        com.example.description: "This label will appear on the web service"
```

Для установки ярлыков (labels) для _контейнеров_ (а не сервиса), используйте ключ `labels` вне секции `deploy`:

```yaml
version: "3"

services:
  web:
    image: web
    labels:
      com.example.description: "This label will appear on all containers for the web service"
```

### `mode`

Может быть _глобальным_ (`global`, строго один контейнер на swarm-ноде) или _реплицированным_ (`replicated`, с указанием количества контейнеров). По умолчанию используется `replicated`. Подробнее можно прочитать в разделе [Реплицированные и глобальные сервисы][replicated_and_global_services].

```yaml
version: '3'

services:
  worker:
    image: dockersamples/examplevotingapp_worker
    deploy:
      mode: global
```

### `placement`

Указание мест размещения контейнеров и их "предпочтений". Наиболее полное описание допустимых опций вы сможете найти в разделах "[constraints][constraints]" и "[preferences][preferences]" соответственно.

```yaml
version: '3.3'

services:
  db:
    image: postgres
    deploy:
      placement:
        constraints:
          - node.role == manager
          - engine.labels.operatingsystem == ubuntu 14.04
        preferences:
          - spread: node.labels.zone
```

### `replicas`

Если у сервиса выбран режим репликации (`replicated`, используется по умолчанию) - вы можете указать количество запускаемых контейнеров у данного сервиса.

```yaml
version: '3'

services:
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 6
```

### `resources`

Настройка ограничений используемых ресурсов.

> **Примечание:** Указанные в данной секции опции перекрывают [более старые ограничения и опции][cpu_and_other_resources], что указаны в Compose-файле для не-swarm режима до версии 3 (`cpu_shares`, `cpu_quota`, `cpuset`, `mem_limit`, `memswap_limit`, `mem_swappiness`), как описано в разделе [обновление с версии 2.x до 3.x][compose_upgrading].

Каждое значение, указанное в данной секции, является аналогом опций для [`docker service create`][service_create].

В приведенном ниже примере сервис `redis` может использовать не более 50 Мб памяти и `0.50` (50%) доступного процессорного времени (CPU), а так же имеет зарезервированные 20 Мб памяти и `0.25` CPU (всегда доступные для него).

```yaml
version: '3'

services:
  redis:
    image: redis:alpine
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
```

> Настройка ограничений ресурсов для не-swarm режима [доступна в этом разделе][cpu_and_other_resources]. Если у вас возникнут дополнительные вопросы - обратите внимание на [этот топик на github.com][github_issue_4513].

#### Исключения класса "Out Of Memory" (OOME)

Если ваши сервисы или контейнеры попытаются использовать объём памяти больше, чем доступен на используемой системе, вы рискуете "поймать" исключение класса "Out Of Memory Exception" (OOME) и контейнер, или сам докер-демон может быть прибит демоном ядра системы ("kernel OOM killer"). Во избежание этого убедитесь в наличии доступных ресурсов на целевой системе и ознакомтесь с разделом [понимание рисков недостатка доступной памяти][understand_the_risks].

### `restart_policy`

Указывает как и в каких случаях необходимо перезапускать контейнеры когда они останавливаются. Замена секции `restart`.

- `condition` (условие): одно из возможных значений - `none` (никогда), `on-failure` (при ошибке) или `any` (всегда) (по умолчанию: `any`).
- `delay` (задержка): Задержка между попытками перезапуска, указывается в формате "[продолжительность][specifying_durations]" (по умолчанию: 0).
- `max_attempts`: Количество предпринимаемых попыток перезапуска перед тем, как прекратить пытаться запустить контейнер (по умолчанию: количество попыток не ограничено). Если контейнер не запустился в пределах указанного "окна" (`window`), эта попытка не учитывается при расчете значения `max_attempts`. Например, если `max_attempts` установлен равным `2`, и перезапуск завершился ошибкой при первой попытке, может быть предпринято более двух попыток перезапуска.
- `window`: Задержка перед принятием решения о том, что перезапуск успешно завершился. Указывается в формате "[продолжительность][specifying_durations]" (по умолчанию: задержка отсутствует).

> Для лучшего понимания лучше прочитать [первоисточник](https://docs.docker.com/compose/compose-file/#restart_policy).

```yaml
version: '3'

services:
  redis:
    image: redis:alpine
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
```

### `update_config`

Настройка **обновления** сервисов.

- `parallelism`: Количество _одновременно_ обновляемых контейнеров. Если установить `0`, то будет происходить одновременное обновление всех контейнеров.
- `delay`: Задержка между обновлениями группы контейнеров (по умолчанию: `0s`).
- `failure_action`: Действие при ошибке обновления. Может принимать значения: `continue`, `rollback`, или `pause` (по умолчанию: `pause`).
- `monitor`: Продолжительность мониторинга на сбой после каждого обновления `(ns|us|ms|s|m|h)` (по умолчанию: `0s`).
- `max_failure_ratio`: Допустимая частота сбоев при обновлении (по умолчанию: `0`).
- `order`: Порядок операций при обновлении. Может принимать значения: `stop-first` (старая задача останавливается перед тем, как запускать новую), или `start-first` (сначала запускается новая задача, а выполняемые задачи ненадолго "перекрываются") (по умолчанию: `stop-first`).

> **Заметка:** Порядок операций при обновлении доступен начиная с версии v3.4 и выше.

```yaml
version: '3.4'

services:
  vote:
    image: dockersamples/examplevotingapp_vote:before
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
        delay: 10s
        order: stop-first
```

### `rollback_config`

> [Версия **3.7**][compose_v3_7] и выше

Настройка **откатов** сервисов в случае ошибки обновления.

- `parallelism`: Количество _одновременно_ откатываемых контейнеров. Если установить `0`, то будет происходить одновременный откат всех контейнеров.
- `delay`: Задержка между откатами группы контейнеров (по умолчанию: `0s`).
- `failure_action`: Действие при провале отката. Может принимать значения: `continue` или `pause` (по умолчанию: `pause`)
- `monitor`: Продолжительность мониторинга на сбой после каждого обновления `(ns|us|ms|s|m|h)` (по умолчанию: `0s`).
- `max_failure_ratio`: Допустимая частота сбоев при откате (по умолчанию: `0`).
- `order`: Порядок операций при откате. Может принимать значения: `stop-first` (старая задача останавливается перед тем, как запускать новую), или `start-first` (сначала запускается новая задача, а выполняемые задачи ненадолго "перекрываются") (по умолчанию: `stop-first`).

### Не поддерживается в контексте `docker stack deploy`

Следующие настройки _не поддерживаются_ командой `docker stack deploy` или настройками в группе `deploy`.

- `build`
- `cgroup_parent`
- `container_name`
- `devices`
- `tmpfs`
- `external_links`
- `links`
- `network_mode`
- `restart`
- `security_opt`
- `stop_signal`
- `sysctls`
- `userns_mode`

> **Заметка:** Смотри раздел [как настраивать тома для сервисов, swarm-ов и docker-stack.yml файлов][volumes_for_services_swarms]. Использование томов поддерживается, но они должны быть сконфигурированы как как именованные тома или связаны с сервисами, которые в свою очередь предоставляют доступ к необходимым томам.

[source_doc]:https://docs.docker.com/compose/compose-file/#deploy
[swarm]:https://docs.docker.com/engine/swarm/
[stack_deploy]:https://docs.docker.com/engine/reference/commandline/stack_deploy/
[compose_v3]:https://docs.docker.com/compose/compose-file/compose-versioning/#version-3
[compose_v3_7]:https://docs.docker.com/compose/compose-file/compose-versioning/#version-37
[service_create]:https://docs.docker.com/engine/reference/commandline/service_create/
[swarm_cli]:https://docs.docker.com/engine/swarm/#swarm-mode-key-concepts-and-tutorial
[network_overlay]:https://docs.docker.com/network/overlay/
[replicated_and_global_services]:https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/#replicated-and-global-services
[constraints]:https://docs.docker.com/engine/reference/commandline/service_create/#specify-service-constraints-constraint
[preferences]:https://docs.docker.com/engine/reference/commandline/service_create/#specify-service-placement-preferences-placement-pref
[cpu_and_other_resources]:https://docs.docker.com/compose/compose-file/compose-file-v2/#cpu-and-other-resources
[compose_upgrading]:https://docs.docker.com/compose/compose-file/compose-versioning/#upgrading
[github_issue_4513]:https://github.com/docker/compose/issues/4513
[understand_the_risks]:https://docs.docker.com/engine/admin/resource_constraints/#understand-the-risks-of-running-out-of-memory
[specifying_durations]:https://docs.docker.com/compose/compose-file/#specifying-durations
[volumes_for_services_swarms]:https://docs.docker.com/compose/compose-file/#volumes-for-services-swarms-and-stack-files
