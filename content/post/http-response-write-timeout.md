---
categories:
- 学习
date: "2020-10-01"
tags:
- Go
title: Go HTTP Response 写超时导致的 EOF 错误
---

前天在联调过程中出现了一个神奇的错误, 错误在 client 端的表现为 http 请求错误 `Get "http://127.0.0.1:8800": EOF`, 但是服务端却没有任何 **异常** 所有的日志都是正常执行

由于只有 client 端的错误, 所以 Google 搜索的处理结果全都不是实际场景导致的(并没有怀疑到服务端出了问题), 无奈只能抓包, 最终问题得以解决

## 原因

server 端处理请求耗时 30s, 但是 http.Server 的 write timeout 设置的时间是 10s, 所以在 handler 处理请求完毕的时候, server 端和 client 端的连接已经被关闭了

但是由于 server 端写入的 data 远远小于 http/net 包中设定的 write buffer 缓冲大小(4096 byte), 所以 bufio 的 Write 方法并没有返回 error

## 抓包

源码: <https://github.com/yakumioto/demo-response-write-timeout>

由于测试环境太过复杂, 所以写了个 demo 复现了整个流程， 以下是 wireshark 导出的 svc 由此可以看出:

1. 客户端通过三次握手和服务端建立了 TCP 连接
2. 客户端正常的发送了 HTTP Request 请求
3. 正常的保持了一段时间的 Keep-Alive
4. 服务端通过四次挥手和客户端断开了连接

```svc
"No.","Time","Source","Destination","Protocol","Length","Info"
"85","3.662590","127.0.0.1","127.0.0.1","TCP","68","55585  >  8800 [SYN] Seq=0 Win=65535 Len=0 MSS=16344 WS=64 TSval=465914251 TSecr=0 SACK_PERM=1"
"86","3.662666","127.0.0.1","127.0.0.1","TCP","68","8800  >  55585 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=16344 WS=64 TSval=465914251 TSecr=465914251 SACK_PERM=1"
"87","3.662675","127.0.0.1","127.0.0.1","TCP","56","55585  >  8800 [ACK] Seq=1 Ack=1 Win=408256 Len=0 TSval=465914251 TSecr=465914251"
"88","3.662681","127.0.0.1","127.0.0.1","TCP","56","[TCP Window Update] 8800  >  55585 [ACK] Seq=1 Ack=1 Win=408256 Len=0 TSval=465914251 TSecr=465914251"
"89","3.662802","127.0.0.1","127.0.0.1","HTTP","151","GET / HTTP/1.1 "
"90","3.662813","127.0.0.1","127.0.0.1","TCP","56","8800  >  55585 [ACK] Seq=1 Ack=96 Win=408192 Len=0 TSval=465914251 TSecr=465914251"
"160","18.792318","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 8800  >  55585 [ACK] Seq=0 Ack=96 Win=408192 Len=0"
"161","18.792325","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 55585  >  8800 [ACK] Seq=95 Ack=1 Win=408256 Len=0"
"162","18.792359","127.0.0.1","127.0.0.1","TCP","56","[TCP Keep-Alive ACK] 55585  >  8800 [ACK] Seq=96 Ack=1 Win=408256 Len=0 TSval=465929251 TSecr=465914251"
"163","18.792363","127.0.0.1","127.0.0.1","TCP","56","[TCP Dup ACK 90#1] 8800  >  55585 [ACK] Seq=1 Ack=96 Win=408192 Len=0 TSval=465929251 TSecr=465914251"
"283","33.925723","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 8800  >  55585 [ACK] Seq=0 Ack=96 Win=408192 Len=0"
"284","33.925731","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 55585  >  8800 [ACK] Seq=95 Ack=1 Win=408256 Len=0"
"285","33.925741","127.0.0.1","127.0.0.1","TCP","56","[TCP Keep-Alive ACK] 55585  >  8800 [ACK] Seq=96 Ack=1 Win=408256 Len=0 TSval=465944251 TSecr=465929251"
"286","33.925749","127.0.0.1","127.0.0.1","TCP","56","[TCP Dup ACK 90#2] 8800  >  55585 [ACK] Seq=1 Ack=96 Win=408192 Len=0 TSval=465944251 TSecr=465929251"
"345","49.031897","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 8800  >  55585 [ACK] Seq=0 Ack=96 Win=408192 Len=0"
"346","49.031903","127.0.0.1","127.0.0.1","TCP","44","[TCP Keep-Alive] 55585  >  8800 [ACK] Seq=95 Ack=1 Win=408256 Len=0"
"347","49.031929","127.0.0.1","127.0.0.1","TCP","56","[TCP Keep-Alive ACK] 55585  >  8800 [ACK] Seq=96 Ack=1 Win=408256 Len=0 TSval=465959251 TSecr=465944251"
"348","49.031932","127.0.0.1","127.0.0.1","TCP","56","[TCP Dup ACK 90#3] 8800  >  55585 [ACK] Seq=1 Ack=96 Win=408192 Len=0 TSval=465959251 TSecr=465944251"
"469","63.667058","127.0.0.1","127.0.0.1","TCP","56","8800  >  55585 [FIN, ACK] Seq=1 Ack=96 Win=408192 Len=0 TSval=465973767 TSecr=465959251"
"470","63.667081","127.0.0.1","127.0.0.1","TCP","56","55585  >  8800 [ACK] Seq=96 Ack=2 Win=408256 Len=0 TSval=465973767 TSecr=465973767"
"471","63.667119","127.0.0.1","127.0.0.1","TCP","56","55585  >  8800 [FIN, ACK] Seq=96 Ack=2 Win=408256 Len=0 TSval=465973767 TSecr=465973767"
"472","63.667147","127.0.0.1","127.0.0.1","TCP","56","8800  >  55585 [ACK] Seq=2 Ack=97 Win=408192 Len=0 TSval=465973767 TSecr=465973767"
```

## 源码解析

既然是源码分析那就从头跟起!!!

### 入口方法, 为了方便定位追踪源码

```go
// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:2854
// 入口函数, 没啥好解释的
func (srv *Server) ListenAndServe() error {
    ...
    return srv.Serve(ln)
}

// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:2907
// 死循环, 监听请求, 并开一个协程处理
func (srv *Server) Serve(l net.Listener) error {
    ...
    for {
        ...
        c := srv.newConn(rw)
        c.setState(c.rwc, StateNew) // before Serve can return
        go c.serve(connCtx)
    }
}
```

### 这里有一些重要的变量需要记录以下, 后续的源码中会涉及到

`b.bufr`: conn 的读 buffer
`b.bufw`: conn 的写 buffer, 大小为 4096 byte
`c.readRequest(ctx)`: 处理了 req 请求, 同时返回了一个 `*response`
`ServeHTTP(w, w.req)`: 最终 w 会一路下传, 到我们自己所写的处理函数中

接下来就看这个 `w` 是如何产生的

```go
// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:1794
func (c *conn) serve(ctx context.Context) {
    ...

    // HTTP/1.x from here on.

    ctx, cancelCtx := context.WithCancel(ctx)
    c.cancelCtx = cancelCtx
    defer cancelCtx()

    c.r = &connReader{conn: c}
    c.bufr = newBufioReader(c.r)
    c.bufw = newBufioWriterSize(checkConnErrorWriter{c}, 4<<10)

    for {
        w, err := c.readRequest(ctx)
        ...
        serverHandler{c.server}.ServeHTTP(w, w.req)
        ...
    }
}
```

`w.w`: 可见 w.w 是 w.cw 的 bufio.Writer 相当于调用 w.w.Write(p []byte) == w.cw.Write(p []byte)
`w.cw`: 可见其类型是 chunkWriter 所以如果调用到 w.w.Write(p []byte) == chunkWriter.Write([]byte)

```go
// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:418
type response struct {
    ...
    w  *bufio.Writer // buffers output in chunks to chunkWriter
    cw chunkWriter
    ...
}

// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:955
func (c *conn) readRequest(ctx context.Context) (w *response, err error) {
    ...
    w = &response{
        conn:          c,
        cancelCtx:     cancelCtx,
        req:           req,
        reqBody:       req.Body,
        handlerHeader: make(Header),
        contentLength: -1,
        closeNotifyCh: make(chan bool, 1),

        // We populate these ahead of time so we're not
        // reading from req.Header after their Handler starts
        // and maybe mutates it (Issue 14940)
        wants10KeepAlive: req.wantsHttp10KeepAlive(),
        wantsClose:       req.wantsClose(),
    }
    if isH2Upgrade {
        w.closeAfterReply = true
    }
    w.cw.res = w
    w.w = newBufioWriterSize(&w.cw, bufferBeforeChunkingSize)
    ...
}
```

`cw.res.conn`: 根据上面的代码发现 conn == w.conn == srv.newConn(rw)
`cw.res.conn.bufw`: 就是 c.bufw = newBufioWriterSize(checkConnErrorWriter{c}, 4<<10), 由此可见 conn write 的缓冲区就是 4096 byte

```go
func (cw *chunkWriter) Write(p []byte) (n int, err error) {
    ...
    n, err = cw.res.conn.bufw.Write(p)
    if cw.chunking && err == nil {
        _, err = cw.res.conn.bufw.Write(crlf)
    }
    if err != nil {
        cw.res.conn.rwc.Close()
    }
    return
}
```

`bufio`: 如果数据长度没有超过 len(b.buf) 数据会 copy 到 b.buf 中, 并不会真正写入 b.wr 中

```go
// file: /usr/local/Cellar/go/1.15.2/libexec/src/bufio/bufio.go:558
type Writer struct {
    err error
    buf []byte
    n   int
    wr  io.Writer
}

// file: /usr/local/Cellar/go/1.15.2/libexec/src/net/http/server.go:368
func (b *Writer) Write(p []byte) (nn int, err error) {
    for len(p) > b.Available() && b.err == nil {
        var n int
        if b.Buffered() == 0 {
            // Large write, empty buffer.
            // Write directly from p to avoid copy.
            n, b.err = b.wr.Write(p)
        } else {
            n = copy(b.buf[b.n:], p)
            b.n += n
            b.Flush()
        }
        nn += n
        p = p[n:]
    }
    if b.err != nil {
        return nn, b.err
    }
    n := copy(b.buf[b.n:], p)
    b.n += n
    nn += n
    return nn, nil
}
```

## 参考

1. <https://github.com/golang/go/issues/21389>
