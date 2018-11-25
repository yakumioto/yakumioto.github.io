---
title: "RaspberryZero网络与OTG配置.md"
date: 2018-11-011 19:08:00
tags:
  - Raspberry
---

买 Raspberry Zero 的原因呢, 是因为钉钉打卡, 每次可能晚了那么几分钟, 但我就是起不来啊...

这篇文章主要讲三个点 `无屏幕 SSH`, `Static IP`, `开启OTG模式`

## SSH

当然在 `ssh` 的时候要保证 Raspberry Zero 是有网的状态, 编辑第二个分区 `wpa-supplicant` 的配置文件 `/etc/wpa_supplicant/wpa_supplicant.conf`

### 基本网络配置

```text
network={
    ssid="testing"
    psk="testingPassword"
}
```

`ssid` 无线网络名称, `psk` 无线网络密码

### 隐藏网络配置

```text
network={
    ssid="testing"
    scan_ssid=1
    psk="testingPassword"
}
```

### 多个网络配置

```text
network={
    ssid="HomeOneSSID"
    psk="passwordOne"
    priority=1
    id_str="homeOne"
}

network={
    ssid="HomeTwoSSID"
    psk="passwordTwo"
    priority=2
    id_str="homeTwo"
}
```

`priority` 网络优先级

### 连接 SSH

如果网络配置没问题的话,现在应该已经连接上了无线网络了, 接下来就是在无屏幕状态下如何 `ssh` 到 Raspberry Zero

挂载第一分区在 `/` 目录创建 `SSH` 文件就可以了, 然后插电启动 Raspberry Zero 等待自动连接到网络后进行后续操作

如果能进路由器管理页面, 那很简单了找到 Raspberry 的 IP, 然后直接 `ssh`

如果没有路由器管理页面的权限, 需要做的事情是 扫描网络中 `22` 端口 开启的机器, 然后找出 Raspberry Zero 的 IP

```text
sudo nmap -sS -O 192.168.199.0/24
```

扫描整个网段 `22` 端口开启的设备, 然后一个一个试过去...

## Static IP

编辑 `/etc/dhcpcd.conf`

```text
interface eth0

static ip_address=192.168.0.2/24
static routers=192.168.0.1
static domain_name_servers=192.168.0.1

interface wlan0

static ip_address=192.168.0.2/24
static routers=192.168.0.1
static domain_name_servers=192.168.0.1
```

照着这个格式写好, 就万事大吉了!

## 开启OTG模式

1. 挂载SD卡的第一个分区
2. 编辑 `config.txt` 在尾部添加一行 `dtoverlay=dwc2` 保存退出
3. 编辑 `cmdline.txt` 在 `rootwait` 后面添加 `modules-load=dwc2,g_ether` 保存退出
4. 插卡重启!

## 参考

- <https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md>
- <https://www.raspberrypi.org/learning/networking-lessons/rpi-static-ip-address/>
- <https://www.raspberrypi.org/documentation/remote-access/ssh/>
- <https://gist.github.com/gbaman/975e2db164b3ca2b51ae11e45e8fd40a>