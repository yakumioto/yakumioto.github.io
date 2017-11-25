---
title: docker caddy 克隆私有仓库遇到的问题
date: 2017-11-04 11:26:45
tags:
---

## 问题描述

我使用的是 `gogs` 作为自己私有的 git server. 正常的将 `.ssh` 目录直接导入到了 `docker` 中. 然后启动 `docker` 报错如下

```bash
Warning: Permanently added the RSA host key for IP address
'xx.xx.xx.xx' to the list of known hosts.
```

想必经常玩vps的人对这个提示并不陌生.. 我们每次是有 `ssh` 尝试连接一台我们从没有连接过服务器都会出现, 但是在 docker 中如何避免这个提示? 

## 解决

其实就是要跳过这个验证, 网上一搜基本就能找到. 将 `StrictHostKeyChecking` 直接配置到 `.ssh/config` 中 就可以了.

```bash
# 文件 .ssh/config
# 以 github.com 为例 自行替换成自己的 git server 地址
Host github.com
    StrictHostKeyChecking no
```

这样请求的时候就会跳过跳过验证直接 clone 代码了.