---
title: "私有-docker-registry-搭建"
date: 2018-08-19 18:14:15
tags:
  - Docker
---

## 简介

这个东西可能并没有你想象中的那么完美, 适合个人使用, 上传后无法删除镜像, 但是有第三方工具帮你删除后面会讲. 如果这几点你都不介意的话, 可以继续往下看了!!!

`docker` 的基础操作我都不会讲, 如果不太了解的话建议去官网学习

必备的程序  `docker-ce`, `docker-compose`.

## 本机搭建

`registry` 的默认端口为 `5000`

如果想将 `hub.docker.com` 上的 `alpine` 做个镜像.

1. `docker pull alpine:latest`
2. `docker tag alpine:latest localhost:5000/alpine:latest`
3. `docker push localhost:5000/alpine:latest`

```yaml
---
version: "2"

services:
  registry:
    image: registry:latest
    restart: always
    volumes:
      - registry:/var/lib/registry

volumes:
  registry:
```

## 配置前端

`registry-frontend` 是 `registry` 的前端, 如果想详细设置可以去 [konradkleine/docker-registry-frontend](https://hub.docker.com/r/konradkleine/docker-registry-frontend/) 这里看.

效果图如下:

![01](/images/私有-docker-registry-搭建-01.png)

```yaml
---
version: "2"

services:

  registry:
    image: registry:latest
    restart: always
    volumes:
      - registry:/var/lib/registry

  registry-frontend:
    image: konradkleine/docker-registry-frontend:v2
    environment:
      ENV_DOCKER_REGISTRY_HOST: registry
      ENV_DOCKER_REGISTRY_PORT: "5000"
      ENV_MODE_BROWSE_ONLY: "true"
    depends_on:
      - registry

volumes:
  registry:
```

## 配置域名与认证

我使用的是 `caddy` 作为我的反向代理服务器, 当然你也可以使用 `nginx` 等.

```yaml
# docker-compose.yaml
---
version: "2"

services:

  caddy:
    image: abiosoft/caddy:latest
    environment:
      ACME_AGREE: "true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/caddy/Caddyfile:/etc/Caddyfile
      - ./config/caddy/.caddy:/root/.caddy

  registry:
    image: registry:latest
    restart: always
    volumes:
      - registry:/var/lib/registry

  registry-frontend:
    image: konradkleine/docker-registry-frontend:v2
    environment:
      ENV_DOCKER_REGISTRY_HOST: registry
      ENV_DOCKER_REGISTRY_PORT: "5000"
      ENV_REGISTRY_PROXY_FQDN: docker.mioto.me
      ENV_REGISTRY_PROXY_PORT: "443"
      ENV_MODE_BROWSE_ONLY: "true"
    depends_on:
      - registry

volumes:
  registry:
```

```txt
# Caddyfile
# {domains} 提换成自己的域名
# 如果不要认证 可以注释掉 `basicauth` 那一行

{domains} {
    tls admin@mioto.me

    basicauth / admin P3MWcbWCV6nyE8imHBbC

    proxy / registry:5000 {
        transparent
    }

    redir 301 {
        if {>X-Forwarded-Proto} is http
            / https://{host}{url}
    }
}
```

## 参考

- <https://caddyserver.com/>
- <https://www.docker.com/>
- <https://hub.docker.com/_/registry/>
- <https://hub.docker.com/r/konradkleine/docker-registry-frontend/>