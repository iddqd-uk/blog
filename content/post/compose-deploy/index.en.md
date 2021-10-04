---
title: "Deploy to Docker Swarm"
slug: compose-deploy
date: 2018-10-15T13:35:50Z
aliases: [/docker/compose-deploy]
image: featured-image.png
categories: [docker]
tags:
- linux
- deploy
- docker-compose
- docker
- devops
---

> This post is translation of [part of documentation][source_doc]

## `deploy`

> [Version 3][compose_v3] only.

Specify configuration related to the deployment and running of services. This only takes effect when deploying to a [swarm][swarm] with [docker stack deploy][stack_deploy], and is ignored by `docker-compose up` and `docker-compose run`.

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

Several sub-options are available:

### `ENDPOINT_MODE`

Specify a service discovery method for external clients connecting to a swarm.

> [Version 3.3][compose_v3] only.

- `endpoint_mode: vip` - Docker assigns the service a virtual IP (VIP) that acts as the “front end” for clients to reach the service on a network. Docker routes requests between the client and available worker nodes for the service, without client knowledge of how many nodes are participating in the service or their IP addresses or ports. (This is the default.)

- `endpoint_mode: dnsrr` - DNS round-robin (DNSRR) service discovery does not use a single virtual IP. Docker sets up DNS entries for the service such that a DNS query for the service name returns a list of IP addresses, and the client connects directly to one of these. DNS round-robin is useful in cases where you want to use your own load balancer, or for Hybrid Windows and Linux applications.

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

The options for `endpoint_mode` also work as flags on the swarm mode CLI command [docker service create][service_create]. For a quick list of all swarm related `docker` commands, see [Swarm mode CLI commands][swarm_cli].

To learn more about service discovery and networking in swarm mode, see [Configure service discovery][network_overlay] in the swarm mode topics.

### `LABELS`

Specify labels for the service. These labels are _only_ set on the service, and _not_ on any containers for the service.

```yaml
version: "3"
services:
  web:
    image: web
    deploy:
      labels:
        com.example.description: "This label will appear on the web service"
```

To set labels on containers instead, use the `labels` key outside of `deploy`:

```yaml
version: "3"
services:
  web:
    image: web
    labels:
      com.example.description: "This label will appear on all containers for the web service"
```

### `MODE`

Either `global` (exactly one container per swarm node) or `replicated` (a specified number of containers). The default is `replicated`. (To learn more, see [Replicated and global services][replicated_and_global_services] in the [swarm][swarm] topics.)

```yaml
version: '3'
services:
  worker:
    image: dockersamples/examplevotingapp_worker
    deploy:
      mode: global
```

### `PLACEMENT`

Specify placement of constraints and preferences. See the docker service create documentation for a full description of the syntax and available types of [constraints][constraints] and [preferences][preferences].

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

### `REPLICAS`

If the service is `replicated` (which is the default), specify the number of containers that should be running at any given time.

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

### `RESOURCES`

Configures resource constraints.

> **Note:** This replaces the [older resource constraint options][cpu_and_other_resources] for non swarm mode in Compose files prior to version 3 (`cpu_shares`, `cpu_quota`, `cpuset`, `mem_limit`, `memswap_limit`, `mem_swappiness`), as described in [Upgrading version 2.x to 3.x][compose_upgrading].

Each of these is a single value, analogous to its [docker service create][service_create] counterpart.

In this general example, the `redis` service is constrained to use no more than 50M of memory and `0.50` (50%) of available processing time (CPU), and has `20M` of memory and `0.25` CPU time reserved (as always available to it).

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

The topics below describe available options to set resource constraints on services or containers in a swarm.

> **Looking for options to set resources on non swarm mode containers?**
>
> The options described here are specific to the `deploy` key and swarm mode. If you want to set resource constraints on non swarm deployments, use [Compose file format version 2 CPU, memory, and other resource options][cpu_and_other_resources]. If you have further questions, refer to the discussion on the GitHub issue [docker/compose/4513][github_issue_4513].

#### Out Of Memory Exceptions (OOME)

If your services or containers attempt to use more memory than the system has available, you may experience an Out Of Memory Exception (OOME) and a container, or the Docker daemon, might be killed by the kernel OOM killer. To prevent this from happening, ensure that your application runs on hosts with adequate memory and see [Understand the risks of running out of memory][understand_the_risks].

### `RESTART_POLICY`

Configures if and how to restart containers when they exit. Replaces `restart`.

- `condition`: One of `none`, `on-failure` or `any` (default: `any`).
- `delay`: How long to wait between restart attempts, specified as a [duration][specifying_durations] (default: 0).
- `max_attempts`: How many times to attempt to restart a container before giving up (default: never give up). If the restart does not succeed within the configured `window`, this attempt doesn’t count toward the configured `max_attempts` value. For example, if `max_attempts` is set to ‘2’, and the restart fails on the first attempt, more than two restarts may be attempted.
- `window`: How long to wait before deciding if a restart has succeeded, specified as a [duration][specifying_durations] (default: decide immediately).

```yaml
version: "3"
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

### `ROLLBACK_CONFIG`

> [Version 3.7 file format][compose_v3_7] and up

Configures how the service should be rollbacked in case of a failing update.

- `parallelism`: The number of containers to rollback at a time. If set to 0, all containers rollback simultaneously.
- `delay`: The time to wait between each container group’s rollback (default 0s).
- `failure_action`: What to do if a rollback fails. One of `continue` or `pause` (default `pause`)
- `monitor`: Duration after each task update to monitor for failure `(ns|us|ms|s|m|h)` (default `0s`).
- `max_failure_ratio`: Failure rate to tolerate during a rollback (default 0).
- `order`: Order of operations during rollbacks. One of `stop-first` (old task is stopped before starting new one), or `start-first` (new task is started first, and the running tasks briefly overlap) (default `stop-first`).

### `UPDATE_CONFIG`

Configures how the service should be updated. Useful for configuring rolling updates.

- `parallelism`: The number of containers to update at a time.
- `delay`: The time to wait between updating a group of containers.
- `failure_action`: What to do if an update fails. One of `continue`, `rollback`, or `pause` (default: `pause`).
- `monitor`: Duration after each task update to monitor for failure `(ns|us|ms|s|m|h)` (default `0s`).
- `max_failure_ratio`: Failure rate to tolerate during an update.
- `order`: Order of operations during updates. One of `stop-first` (old task is stopped before starting new one), or `start-first` (new task is started first, and the running tasks briefly overlap) (default `stop-first`). **Note:** Only supported for v3.4 and higher.

> **Note:** order is only supported for v3.4 and higher of the compose file format.

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

### NOT SUPPORTED FOR `DOCKER STACK DEPLOY`

The following sub-options (supported for `docker-compose up` and `docker-compose run`) are _not supported_ for `docker stack deploy` or the `deploy` key.

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

> **Tip:** See the section on [how to configure volumes for services, swarms, and docker-stack.yml files][volumes_for_services_swarms]. Volumes are supported but to work with swarms and services, they must be configured as named volumes or associated with services that are constrained to nodes with access to the requisite volumes.

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
