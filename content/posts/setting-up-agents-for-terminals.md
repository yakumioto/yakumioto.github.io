---
categories:
- 学习
date: "2018-10-05 16:21:00"
tags:
- Linux
title: 为终端设置代理
---

现在一般都是使用 `SS FQ` 了吧, 所以都是 `SOCKS5` 代理, 但是在终端有些程序是不支持 `SOCKS5` 的, 比如 `go get`

## 方法一

如果你的 `SS` 目前 `Cow` 支持的加密算法有: `aes-128-cfb, aes-192-cfb, aes-256-cfb, bf-cfb, cast5-cfb, des-cfb, rc4-md5, chacha20, salsa20, rc4, table`

安装教程参见 <https://github.com/cyfdecyf/cow#快速开始>

## 方法二

如果你用的 `SS` 加密算法不在以上支持的情况

可以先使用 `ss-local` 在本地开启 `SOCKS5` 然后在通过  `Cow` 将 `SOCKS5` 转 `HTTP`
