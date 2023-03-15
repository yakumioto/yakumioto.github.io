---
categories:
- 学习
date: "2019-05-07 08:45:00"
tags:
- Go
title: Go 解析 ECPrivate Key 遇到的问题
---

最近在做 `fabric` 证书私钥管理系统, 遇到的一个问题, 在使用 `x509.ParseECPrivateKey()` 方法的时候会直接报错, 而 `fabric` 确实用的是 `椭圆曲线算法`

错误输出: `x509: failed to parse EC private key: asn1: structure error: tags don't match (4 vs {class:0 tag:16 length:19 isCompound:true}) {optional:false explicit:false application:false private:false defaultValue:<nil> tag:<nil> stringType:0 timeType:0 set:false omitEmpty:false}  @5`

原因是 `fabric` 将私钥转成 `pem` 格式的时候使用的方法是 `x509.MarshalPKCS8PrivateKey()`

## 解决办法

```go
block, _ := pem.Decode(pemBytes)

key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
checkErr(err)

switch priv := key.(type) {
case *ecdsa.PrivateKey:
  // do something
}
```
