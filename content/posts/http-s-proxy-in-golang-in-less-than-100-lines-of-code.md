---
categories:
- 学习
date: "2019-08-21"
tags:
- Go
title: Go 100 行实现 HTTP(S) 正向代理
---

目标是现实一个 HTTP HTTPS 的代理服务器, 目前代理的实现方法有两种

**普通代理**: 这种代理扮演的是中间人角色, 对于客户端来说, 它就服务器, 对于服务端来说, 它是客户端,
它负责在中间来回传递 HTTP 报文

**隧道代理**: 它是通过 HTTP 正文部分(body) 完成代理, 以 HTTP 的方式实现基于 TCP 的应用层协议代理,
这种代理使用 HTTP 的 CONNECT 方法建立连接

这是一次 HTTP 的请求, 用 `\r\n` 进行换行, 碰到连续两个 `\r\n` 后内容为请求数据, 分为以下几个部分

1. 请求行 (request line)
2. 请求头 (header)
3. 空行
4. 请求数据 (body)

```bash
curl -Lv http://baidu.com

> GET / HTTP/1.1
> Host: baidu.com
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Thu, 25 Jun 2020 12:12:32 GMT
< Server: Apache
< Last-Modified: Tue, 12 Jan 2010 13:48:00 GMT
< ETag: "51-47cf7e6ee8400"
< Accept-Ranges: bytes
< Content-Length: 81
< Cache-Control: max-age=86400
< Expires: Fri, 26 Jun 2020 12:12:32 GMT
< Connection: Keep-Alive
< Content-Type: text/html
<
<html>
<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">
</html>
```

## 实现

```go
package main

import (
    "io"
    "log"
    "net"
    "net/http"
    "time"
)

func handleTunneling(w http.ResponseWriter, r *http.Request) {
    destConn, err := net.DialTimeout("tcp", r.Host, 10*time.Second)
    if err != nil {
        http.Error(w, err.Error(), http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
    hijacker, ok := w.(http.Hijacker)
    if !ok {
        http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
        return
    }
    clientConn, _, err := hijacker.Hijack()
    if err != nil {
        http.Error(w, err.Error(), http.StatusServiceUnavailable)
    }
    go transfer(destConn, clientConn)
    go transfer(clientConn, destConn)
}

func transfer(destination io.WriteCloser, source io.ReadCloser) {
    defer destination.Close()
    defer source.Close()
    io.Copy(destination, source)
}

func handleHTTP(w http.ResponseWriter, req *http.Request) {
    resp, err := http.DefaultTransport.RoundTrip(req)
    if err != nil {
        http.Error(w, err.Error(), http.StatusServiceUnavailable)
        return
    }
    defer resp.Body.Close()
    copyHeader(w.Header(), resp.Header)
    w.WriteHeader(resp.StatusCode)
    io.Copy(w, resp.Body)
}

func copyHeader(dst, src http.Header) {
    for k, vv := range src {
        for _, v := range vv {
            dst.Add(k, v)
        }
    }
}

func main() {
    server := &http.Server{
        Addr: ":8888",
        Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if r.Method == http.MethodConnect {
                handleTunneling(w, r)
            } else {
                handleHTTP(w, r)
            }
        }),
        // Disable HTTP/2.
        TLSNextProto: make(map[string]func(*http.Server, *tls.Conn, http.Handler)),
    }

    log.Fatal(server.ListenAndServe())
}
```

以上代码不适用于生产环境

上述代码实现了普通代理和隧道代理两个方法, 通过判断请求方是否使用 CONNECT 方法请求代理服务器
来区分不同的处理逻辑

```go
http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    if r.Method == http.MethodConnect {
        handleTunneling(w, r)
    } else {
        handleHTTP(w, r)
    }
})
```

基于普通代理的逻辑是容易理解的, 这里主要看一下是如何实现基于隧道代理的, `handleTunneling` 
第一步是建立和目标服务器的连接

```go
destConn, err := net.DialTimeout("tcp", r.Host, 10*time.Second)
if err != nil {
    http.Error(w, err.Error(), http.StatusServiceUnavailable)
    return
 }
 w.WriteHeader(http.StatusOK)
```

下一步是劫持 HTTP 服务维持的连接, `net.Conn` 类型

```go
hijacker, ok := w.(http.Hijacker)
    if !ok {
        http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
        return
    }
    clientConn, _, err := hijacker.Hijack()
    if err != nil {
        http.Error(w, err.Error(), http.StatusServiceUnavailable)
    }
```

[Hijacker interface](https://golang.org/pkg/net/http/#Hijacker) 获取连接后, 调用者来
维护此连接, HTTP 标准库就不会在负责管理了

这时已经建立了两个 TCP 连接(客户端 -> 代理端, 代理端 -> 目标服务器), 最后一步就是互相转发
他们的消息

```go
go transfer(destConn, clientConn)
go transfer(clientConn, destConn)
```

## 测试

使用 Chrome:

```bash
Chrome --proxy-server=https://localhost:8888
```

使用 Curl:

```bash
curl -Lv --proxy https://localhost:8888 --proxy-cacert server.pem https://baidu.com
```

## 参考

1. <https://medium.com/@mlowicki/http-s-proxy-in-golang-in-less-than-100-lines-of-code-6a51c2f2c38c>
2. <https://imququ.com/post/web-proxy.html>
