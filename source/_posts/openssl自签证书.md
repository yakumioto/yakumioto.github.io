---
title: "openssl自签证书"
date: 2018-01-29 21:38:31
tags:
  - openssl
---

最开始主要是想玩玩 `Go http 2 Push` 的, 但是发现以前那种最简单的自签 `Chrome58+` 后就不认了...

查询后才知道 `Chrome58+` 后只允许包含SAN(Subject Alternative Name)信息的证书.

<!--more-->

## 重新制作包含SAN的自签证书

### 生成 Root CA private key

```bash
openssl genrsa -out rootCA.key 2048
```

### 生成 RootCA

rootCA.pem.conf 主要是方便自己以后生成的, 不用重复工作.

```file
[ req ]
default_bits        = 2048
default_md          = sha256
distinguished_name  = subject

[ subject ]
countryName                     = Country Name (2 letter code)
countryName_default             = CN

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Beijing

localityName                    = Locality Name (eg, city)
localityName_default            = Beijing

organizationName                = Organizational Name
organizationName_default        = Yaku Mioto Co., Ltd

organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  =

commonName                      = Common Name (e.g. server FQDN or YOUR name)
commonName_default              = Yaku Mioto Root CA
```

```bash
openssl req \
        -new \
        -x509 \
        -nodes \
        -sha256 \
        -days 3650 \
        -key rootCA.key \
        -config rootCA.pem.conf \
        -out rootCA.pem
```

### 生成 证书请求 CSR 

server.csr.conf 同理. 减少工作量.

```file
[ req ]
default_bits        = 2048
default_md          = sha256
distinguished_name  = subject

[ subject ]
countryName                     = Country Name (2 letter code)
countryName_default             = CN

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Beijing

localityName                    = Locality Name (eg, city)
localityName_default            = Beijing

organizationName                = Organizational Name
organizationName_default        = Yaku Mioto Co., Ltd
```

```bash
openssl req \
        -new \
        -nodes \
        -sha256 \
        -config server.scr.conf \
        -newkey rsa:2048 \
        -keyout server.key \
        -out server.csr
```

### 签发证书

创建 v3.ext file, 支持了多域名多IP. 这是个好东西啊, https 负载均衡.

```file
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = miotombp.local
```

```bash
openssl x509 \
        -req \
        -sha256 \
        -days 3650 \
        -CA rootCA.pem \
        -CAcreateserial \
         -extfile v3.ext \
        -CAkey rootCA.key \
        -in server.csr \
        -out server.crt
```

大功告成, 至于怎么添加到系统信任, 那就是各个操作系统的事情了.

## 参考

[Chrome 58不允許沒有SAN的自簽憑證](https://medium.com/@klaycsy/chrome-58%E4%B8%8D%E5%85%81%E8%A8%B1%E6%B2%92%E6%9C%89san%E7%9A%84%E8%87%AA%E7%B0%BD%E6%86%91%E8%AD%89-12ca7029a933)
[Chrome 58 - Not secure, certificates must have Subject Alternative Name](https://communities.ca.com/thread/241776307)