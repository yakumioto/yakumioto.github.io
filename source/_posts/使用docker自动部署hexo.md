---
title: "使用docker自动部署hexo"
date: 2017-11-26 22:16:29
tags:
  - Docker
  - Hexo
---

使用这种实现自动部署 `hexo` 必须有台自己的服务器, 如果没有的话我也没办法~~

## 原理

我实现的原理其实很简单. 当 `source` 被提交后, 触发 `webhook` 然后通过执行 `bash script` 自动进行编译部署

<!-- more -->

## 实现

给 `hexo` 准备个仓库, 例: `github.com/xxxx/hexo-source`, 如果你有私有仓库 如 `gogs` `gitlib` 等都可以

在 `hexo` 的根目录创建一个  `deploy.sh` 的脚本

```bash
#/bin/bash
set -ev
export TZ='Asia/Shanghai'

npm install hexo-cli -g

npm install

hexo g -d
```

制作 `node-caddy` 的 `docker`, 当然也可以使用我已经写好的. [yakumioto/node-caddy](https://hub.docker.com/r/yakumioto/node-caddy/), 并编写 `Caddyfile`, 因为我使用的是自己部署的 `Gogs` 所以引用了 `key`

```caddy
:80 {
    gzip
    git {
        repo git@git.mioto.me:yakumioto/mioto.me.git
        branch master
        key /root/.ssh/id_rsa
        hook /webhook miotoyaku
        then bash ./deploy.sh
    }
}
```

`docker-compose.yaml`

```docker
ci-blog:
    image: yakumioto/node-caddy:latest
    restart: always
    ports:
      - "8777:80"
    volumes:
      - ~/.ssh:/root/.ssh
      - ./configs/caddy/Caddyfile.ci:/etc/Caddyfile
      - ./configs/caddy/.caddy:/root/.caddy
      - ../volumes/caddy/ci-blog:/srv
```

到这里基本就算完成了