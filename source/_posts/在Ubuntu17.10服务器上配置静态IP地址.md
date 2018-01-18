---
title: "[译] 在Ubuntu 17.10服务器上配置静态IP地址"
date: 2017-12-05 15:54:50
tags:
  - Ubuntu
---

原文: https://websiteforstudents.com/configuring-static-ips-ubuntu-17-10-servers/

`Ubuntu 17.10` 的时候网络配置方法完全改变了, 是否听说过 `NetPlan`?可能并没有吧~, `NetPlan` 是 `Ubuntu 17.10` 中引入的一种新的网络配置工具，用于管理网络设置.

`NetPlan` 的配置文件是 `YAML` 格式的, 所以配置起来也不算麻烦~

`NetPlan` 取代了以前在 `/etc/network/interfaces` 以前用来配置Ubuntu网络接口的文件. 现在你必须使用 `/etc/netplan/*.yaml` 来配置

以下是简短的例子教你使用 `NetPlan` 来配置 `Ubuntu` 的静态网络.

新的配置文件目录在 `/etc/netplan` 文件夹中, 使用名为 `01-netcfg.yaml` 的文件作为第一的配置文件. 一下是 `DHCP` 的默认配置.

<!-- more -->

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
 version: 2
 renderer: networkd
 ethernets:
   ens33:
     dhcp4: yes
     dhcp6: yes
```

如果需要应用, 就执行以下命令.

```bash
sudo netplan apply
```

## 配置静态IP

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
 version: 2
 renderer: networkd
 ethernets:
   ens33:
     dhcp4: no
     dhcp6: no
     addresses: [192.168.1.2/24]
     gateway4: 192.168.1.1
     nameservers:
       addresses: [8.8.8.8,8.8.4.4]
```

你也可以添加 `IPv6` 的地址, 用 `,` 进行分隔

```yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
 version: 2
 renderer: networkd
 ethernets:
   ens33:
     dhcp4: no
     dhcp6: no
     addresses: [192.168.1.2/24, '2001:1::2/64']
     gateway4: 192.168.1.1
     nameservers:
       addresses: [8.8.8.8,8.8.4.4]
```





