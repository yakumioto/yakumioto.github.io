---
categories:
- 学习
date: "2021-09-24T10:30:23+08:00"
tags:
- Diary
- Bitwarden
title: Bitwarden 白皮书简析
---

1Password 太贵了，$2.99 和 $4.99 分别对应单人和家庭套餐！！！现在的 1password 收费模式也转向了订阅付费，同时架构也转向了 CS 架构，所以本质上和 Bitwarden 也差不多了。

> Bitwarden 是一款自由且开源的密码管理服务，用户可在加密的保管库中存储敏感信息（例如网站登录凭据）。Bitwarden 平台提供有多种客户端应用程序，包括网页用户界面、桌面应用，浏览器扩展、移动应用以及命令行界面。Bitwarden 提供云端托管服务，并支持自行部署解决方案。 -- [维基百科](https://zh.wikipedia.org/wiki/Bitwarden)

## Bitwarden 安全原则

- 端到端加密：所有的密码和私人数据都通过 AES-256 进行加密。所有的加密密钥均在客户端生成和管理，加密过程均在客户端完成。
- 零知识加密：Bitwarden 服务端不存储你的主密钥以及加密密钥，你的数据使用你的个人邮箱以及主密钥进行加密。
- 源代码可用：代码完全开源，并可自行编译使用。
- 隐私设计：所有登录信息在你的设备中进行加密后在存储到 Bitwarden服务器的保管库中，并将保管库同步到所用你的设备，你的数据采用 AES-CBC 256 位加密、加盐散列和 PBKDF2 SHA-256 进行密封。
- 安全审计与合规：Open source and third-party audited, Bitwarden complies with AICPA SOC2 Type 2 / Privacy Shield, GDPR, and CCPA regulations.

## Bitwarden 核心概念

### 主密钥（Master Key）

最核心的密钥，所有后续的密钥和加密密钥均通过主密钥派生，主密钥也是解密所有登录信息以及私人数据的唯一密钥，丢失会导致无法获取已经保存的数据，泄漏将导致所有的数据公之于众。所以主密钥复杂点毕竟你所有的密钥都不需要记了，主密钥在特别简单岂不是很危险？

伪代码：

```
masterKeyHash = pbkdf2(masterKey, email)
```

### 主密钥哈希

用来鉴权登录，身份认证，从 Bitwarden 服务端获取密码保管库。

伪代码：

```
masterKeyHashHash = pbkdf2(masterKeyHash, masterKey)
```

### 扩展主密钥（Stretched Master Key）

通过主密钥派生出加密密钥和签名密钥，并将两个密钥拼接成扩展主密钥。

扩展主密钥会基于 AES-CBC-256 算法加密一个用来加密你所有数据的对称密钥，所以加密密钥只能通过扩展主密钥解密获取，而扩展密钥又是基于主密钥派生而来。

伪代码：

```
encKey = hkdf.expand(masterKeyHash, "enc")
macKey = hkdf.expand(masterKeyHash, "mac")

stretchedMasterKey = append(encKey, macKey)
```

### 对称密钥（Symmetric Key）

用来对所有数据加密的加密密钥。

加密密钥通过 CSPRNG（Cryptographically Secure Pseudo-Random Number Generator）伪随机数产生器生成。包含加密密钥和签名密钥，每个 key 长度均为 256 bits。

伪代码:

```
encKey = CSPRNG(256)
macKey = CSPRNG(256)

symmetricKey = append(encKey, macKey)
```

对称密钥会被扩展主密钥加密后存储到 Bitwarden 服务器，用户身份认证成功后会返回加密数据到客户端，客户端可以通过扩展主密钥解密出加密密钥并用来解密其他的数据。

伪代码：

```
protectedSymmetricKey = append(encryptionType, ".", base64(iv), "|", base64(ciphertext), "|", base64(signtext))

// example: 2.4GQFqhW/5oTd201fW1ypng==|PUTTd9HqXIyYTPcqkzEQrUY0C8/AiuRgRiA3ayJ1hKA=|BVpzevtEsMrCq0x3oFuARvWixusdEtdyYTaOgoGycgI=
```

### 非对称密钥（RSA Key Pair）

原理基本同上，主要用于组织共享密钥库的加解密，这里就不详细介绍了。

## 简述原理

相信看了以上核心概念的朋友们已经大概理解的 Bitwarden 的设计理念了。

所有的密钥都只存在于当前客户端的内存中，主密钥还存在于你的脑袋里，所有的加密解密都在客户端中完成，服务端仅存储加密后的数据。

### 客户端到服务端

1. 主密钥 --（派生）--> 扩展主密钥
2. 扩展主密钥 --（加密）--> 随机生成的加密密钥（账户创建之初生成后续都是使用）
3. 扩展主密钥 --（加密）--> 随机生成的非对称密钥（账户创建之初生成后续都是使用）
4. 加密后的加密密钥和非对称密钥 --（存储）--> Bitwarden 服务器
5. 加密密钥 --（加密）--> 登录信息、安全笔记、信用卡、身份等数据
6. 加密数据 --（存储）--> Bitwarden 服务器

### 服务端到客户端

1. 主密钥哈希 --（身份认证）--> 服务端
2. 获取加密后的加密密钥和非对称密钥 --（解密）--> 通过扩展主密钥解密对应的数据放到内存中
3. 获取加密数据 --（解密）--> 通过加密密钥以及非对称密钥解密所需要使用的数据

## 写在最后

如果主密钥不慎泄漏需要及时更换主密钥以及轮换加密密钥（主密钥泄漏会导致加密密钥不安全），轮换加密密钥会重新解加密所有的数据。

## 参考资料

- <https://bitwarden.com/help/article/bitwarden-security-white-paper>
- <https://bitwarden.com/help/crypto.html>