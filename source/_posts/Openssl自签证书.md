---
title: "Openssl 自签证书"
date: 2018-03-20 21:38:00
---

## 生成 Root CA private key

```sh
openssl genrsa -out rootCA.key 2048
```

## 制作 RootCA

```sh
# 创建 openssl configuration file rootCA.pem.conf

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

```sh
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

## 生成 证书请求 CSR

```sh
# 创建 openssl configuration file server.scr.conf

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
commonName_default              = miotombp.local
```

```sh
openssl req \
        -new \
        -nodes \
        -sha256 \
        -config server.scr.conf \
        -newkey rsa:2048 \
        -keyout server.key \
        -out server.csr
```

## 签发证书

```sh
# 创建 v3.ext file

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = miotombp.local
```

```sh
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

## 参考

忘记了.. 原作者如有看到请告知, 多有得罪.. 
