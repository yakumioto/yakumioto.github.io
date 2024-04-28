---
categories:
- 学习
date: "2024-04-28T18:16:29+08:00"
tags:
- Docker
title: 离线环境下使用 Docker Buildx 与 Docker Registry 实现多平台镜像构建
---

在软件开发与部署过程中，我们经常需要构建适用于不同平台和架构的 Docker 镜像。然而，在离线环境下，由于无法访问互联网，构建多平台镜像变得颇具挑战。本文将介绍如何在离线环境下使用 Docker Buildx 与 Docker Registry 实现多平台镜像构建。

在离线环境下，我们无法安装 QEMU 环境，所以只能采用基于容器的 BuildX 环境，而基于容器的 Buildx 环境并不会从本地的Docker中查询镜像，而是从远端拉取镜像。因此，我们需要事先准备好所需的镜像，并在本地搭建一个 Docker Registry 用于存储和分发这些镜像。

通过结合使用 Docker Buildx 与本地 Docker Registry，我们可以在离线环境下高效地构建和分发多平台 Docker 镜像。

## 详细步骤与命令解释

### 1. 准备所需镜像

首先，我们需要准备两个关键镜像：

- `registry:latest`：用于搭建本地 Docker Registry。
- `moby/buildkit:buildx-stable-1`：包含了 Docker Buildx 所需的 BuildKit 和 QEMU，用于支持多平台构建。

### 2. 启动 Docker Registry

使用以下命令启动一个本地 Docker Registry：

```bash
docker run -itd -v $(pwd)/registry:/var/lib/registry -p 5000:5000 --restart=always --name registry registry:latest
```

- `-v $(pwd)/registry:/var/lib/registry`：将宿主机上的 `$(pwd)/registry` 目录挂载到容器内的 `/var/lib/registry` 目录，用于持久化存储镜像数据。
- `-p 5000:5000`：将容器内的 5000 端口映射到宿主机的 5000 端口，允许从宿主机访问 Registry。
- `--restart=always`：设置容器在启动时总是重启，确保 Registry 服务的可用性。
- `--name registry`：为容器指定一个名称，方便后续管理。

### 3. 创建 Docker Buildx 构建器

#### 3.1 重命名并推送 BuildKit 镜像到本地 Registry

假设宿主机的 IP 地址为 `192.168.10.10`，我们需要将 `moby/buildkit:buildx-stable-1` 镜像重命名并推送到本地 Registry：

```bash
docker tag moby/buildkit:buildx-stable-1 192.168.10.10:5000/moby/buildkit:buildx-stable-1
docker push 192.168.10.10:5000/moby/buildkit:buildx-stable-1
```

如果遇到推送镜像到本地 Registry 的问题，可以将 `192.168.10.10:5000` 添加到 Docker 守护进程的配置文件 `/etc/docker/daemon.json` 中：

```json
{
  "insecure-registries": ["192.168.10.10:5000"]
}
```

#### 3.2 创建 BuildKit 配置文件

创建 BuildKit 配置文件 `/root/.docker/buildx/buildkitd.default.toml`，内容如下：

```toml
[registry."192.168.10.10:5000"]
http = true
insecure = true
```

这个配置文件指定了使用本地 Registry 时的一些设置，如允许使用 HTTP 协议和忽略 SSL 证书验证。

#### 3.3 创建 Docker Buildx 构建器

使用以下命令创建一个名为 `cross-builder` 的 Docker Buildx 构建器：

```bash
docker buildx create --use --platform linux/amd64,linux/arm64 --name cross-builder --driver docker-container --driver-opt image=192.168.10.10:5000/moby/buildkit:buildx-stable-1 --buildkitd-config ~/.docker/buildx/buildkitd.default.toml --bootstrap
```

- `--use`：创建构建器后立即切换为当前使用的构建器。
- `--platform linux/amd64,linux/arm64`：指定支持的目标平台，这里支持 `linux/amd64` 和 `linux/arm64` 两个平台。
- `--name cross-builder`：指定构建器的名称。
- `--driver docker-container`：使用 `docker-container` 驱动，即在容器中运行 BuildKit。
- `--driver-opt image=192.168.10.10:5000/moby/buildkit:buildx-stable-1`：指定使用的 BuildKit 镜像。
- `--buildkitd-config /root/.docker/buildx/buildkitd.default.toml`：指定 BuildKit 的配置文件。
- `--bootstrap`: 直接初始化此构建器

#### 3.4 验证构建器状态

使用以下命令验证构建器状态：

```bash
docker buildx ls
```

输出结果应该类似于：

```
NAME/NODE            DRIVER/ENDPOINT                   STATUS    BUILDKIT   PLATFORMS
cross-builder*       docker-container
 \_ cross-builder0    \_ unix:///var/run/docker.sock   running   v0.13.2    linux/amd64*, linux/arm64*, linux/amd64/v2, linux/amd64/v3, linux/386
default              docker
 \_ default           \_ default                       running   v0.13.1    linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
```

### 4. 使用本地 Registry 的技巧

为了高效地使用本地 Registry，我们可以将不同平台的镜像推送到 Registry 中，并使用 Docker Manifest 将它们聚合为一个多平台镜像。

以 Ubuntu 24.04 为例，假设我们已经在本地拉取了 `linux/amd64` 和 `linux/arm64` 两个平台的镜像：

```bash
# 拉取 linux/amd64 平台的 Ubuntu 24.04 镜像
docker pull --platform linux/amd64 ubuntu:24.04
# 重命名镜像并推送到本地 Registry
docker tag ubuntu:24.04 192.168.10.10:5000/ubuntu-amd64:24.04
docker push 192.168.10.10:5000/ubuntu-amd64:24.04

# 拉取 linux/arm64 平台的 Ubuntu 24.04 镜像
docker pull --platform linux/arm64 ubuntu:24.04
# 重命名镜像并推送到本地 Registry
docker tag ubuntu:24.04 192.168.10.10:5000/ubuntu-arm64:24.04
docker push 192.168.10.10:5000/ubuntu-arm64:24.04
```

接下来，使用 Docker Manifest 将这两个平台的镜像聚合为一个多平台镜像：

```bash
docker manifest create --insecure 192.168.10.10:5000/ubuntu:24.04 192.168.10.10:5000/ubuntu-amd64:24.04 192.168.10.10:5000/ubuntu-arm64:24.04
docker manifest push --insecure 192.168.10.10:5000/ubuntu:24.04
```

现在，我们就可以在构建多平台镜像时，直接从本地 Registry 拉取 `192.168.10.10:5000/ubuntu:24.04` 镜像，而无需考虑具体的平台。

## 总结

在离线环境下构建多平台 Docker 镜像具有一定的挑战性，但通过合理使用 Docker Buildx 和 Docker Registry，我们可以高效地实现这一目标。本文详细介绍了相关的步骤和命令，希望对您在离线环境下的 Docker 镜像构建工作有所帮助。

## 参考

- <https://docs.docker.com/reference/cli/docker/buildx/>
- <https://github.com/docker/buildx/discussions/1088>
- <https://github.com/moby/buildkit/blob/master/docs/buildkitd.toml.md>
- <https://community.arm.com/arm-community-blogs/b/tools-software-ides-blog/posts/deploying-multi-architecture-docker-registry>