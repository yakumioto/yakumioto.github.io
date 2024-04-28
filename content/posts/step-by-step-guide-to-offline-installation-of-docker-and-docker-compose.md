---
categories:
- 学习
date: "2024-04-28T08:16:29+08:00"
tags:
- Docker
title: "离线安装 Docker 和 Docker Compose 详细教程"
---

Docker 是一种广泛使用的容器化平台，它可以让开发者将应用程序和依赖打包到一个可移植的容器中，从而简化了应用程序的部署和管理。Docker Compose 是一个用于定义和运行多容器 Docker 应用程序的工具。本文将详细介绍如何在离线环境下安装 Docker 和 Docker Compose。

## 准备工作

在开始安装之前，请确保您的系统满足以下要求：

- Linux 操作系统（本文以 CentOS 7 为例）
- 可以使用 `root` 用户或具有 `sudo` 权限的用户进行操作
- 已经下载了 Docker 和 Docker Compose 的二进制程序包

## 下载 Docker 二进制程序包

由于是离线安装，我们需要提前下载 Docker 的二进制程序包。您可以在有网络连接的机器上访问以下地址下载对应版本的程序包：

```
https://download.docker.com/linux/static/stable/x86_64/docker-26.1.0.tgz
```

请将 `x86_64` 替换为您系统的实际架构，可以使用 `uname -m` 命令查看。

## 安装 Docker

1. 将下载好的 Docker 二进制程序包上传到目标机器上，并解压：

```bash
tar -xvf docker-26.1.0.tgz
```

2. 将 Docker 二进制文件移动到 `/usr/local/bin` 目录：

```bash
mv docker/* /usr/local/bin/
```

3. 为 Docker 二进制文件创建软链接到 `/usr/bin` 目录：

```bash
ln -s /usr/local/bin/docker /usr/bin/docker
ln -s /usr/local/bin/dockerd /usr/bin/dockerd
ln -s /usr/local/bin/docker-proxy /usr/bin/docker-proxy
ln -s /usr/local/bin/docker-init /usr/bin/docker-init
ln -s /usr/local/bin/ctr /usr/bin/ctr
ln -s /usr/local/bin/runc /usr/bin/runc
ln -s /usr/local/bin/containerd /usr/bin/containerd
ln -s /usr/local/bin/containerd-shim-runc-v2 /usr/bin/containerd-shim-runc-v2
```

4. 下载 Docker 的 systemd 服务文件：

```bash
wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service -O /etc/systemd/system/docker.service
wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.target -O /etc/systemd/system/docker.target
```

5. 下载 containerd 的 systemd 服务文件：

```bash
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service
```

6. 启用并启动 containerd 服务：

```bash
systemctl enable --now containerd
```

7. 启用并启动 Docker 服务：

```bash
systemctl enable --now docker
```

## 安装 Docker Compose

1. 下载 Docker Compose 二进制文件：

```bash
curl -SL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
```

请将 `x86_64` 替换为您系统的实际架构。

2. 为 Docker Compose 创建软链接到 `/usr/bin` 目录：

```bash
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

3. 为 Docker Compose 二进制文件添加执行权限：

```bash
chmod +x /usr/local/bin/docker-compose
```

## 验证安装

安装完成后，可以使用以下命令验证 Docker 和 Docker Compose 是否安装成功：

```bash
docker version
docker-compose version
```

如果能够看到 Docker 和 Docker Compose 的版本信息，说明安装成功。

## 结语

本文详细介绍了如何在离线环境下安装 Docker 和 Docker Compose。通过下载 Docker 和 Docker Compose 的二进制程序包，并将其解压到指定目录，再配置 systemd 服务文件，最后启动 containerd 和 Docker 服务，就可以在离线环境下使用 Docker 和 Docker Compose 了。希望本文对您有所帮助，如有任何问题，欢迎留言讨论。