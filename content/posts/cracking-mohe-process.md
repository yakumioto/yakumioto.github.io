---
categories:
- 学习
date: "2019-06-07"
tags:
- Crack
title: 破解某Wi-Fi探针魔盒的过程
---

有个老同学，在老家做销售工作， 某一天忽然联系我说我有个路由器可以扫描周边的 `MAC Address` 直接得到手机号，我一听这个牛逼啊，然后就让把路由器发来玩玩了

这东西有两个部分一个是手机应用程序，一个是路由器。

## App抓包

最初设想路由器既然要用 `Wi-Fi` 手机当作热点数据必定经过手机，说干就干，下载了个 `HttpCanary` 然后对 `App` 抓包

过滤掉没用的接口后得到了两个核心接口（说真的 App 设计的真心让人恶心，所有权限都要可能为了读取手机上的联系人把）

```text
用来获取已经匹配到的手机号的接口
GET http://x.hnyzlp.com/api/merchart/Operative/phone

用来设置心跳的接口，同时设置经纬度
GET http://x.hnyzlp.com/api/merchart/Operative/set_address
```

到此为止并没有 `MAC` 实际发出的地址， 所以由此可证明路由器直接将数据发送到了远端服务器，这条路被斩断了

## 路由器抓包

起初想的是通过 `ARP` 诈骗让自己家的路由器把数据发送到我指定的设备来实现抓包，但是！Mac 下各种问题，搞了一个多小时没搞定，卒！

后来想起来我的路由器是可编程的啊！，于是乎找了个 `AC68U` 可用的 `tcpdump` 路由器上抓指定网卡的的指定IP，然后！又得到了两个核心接口

```text
用来设置路由器心跳， 一分钟请求一次 获取路由器上的运行时间， ARM 状况 等。
POST http://api.swsf3.cn/api_v1/remotecontrol

用来发送 mac 地址到服务端， 频率是 30 秒一次
POST http://api.swsf3.cn/api_v2/report
```

由此可见所有东西都全了！， 上传数据的接口， 以及查看数据的接口