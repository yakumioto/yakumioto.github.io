---
categories:
- 学习
date: "2017-08-09 13:05:00"
tags:
- Go
- Negroni
title: Negroni 源码分析
---

`negroni` 用了很久很久了, 一直觉得很不错, 目前为止核心源码只有 `175` 行, 很适合用来学习 `Go`

## 初始化

`New` 将传入的 `handlers` 构建成链表并保存的过程

```go
type Handler interface {
    ServeHTTP(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc)
}

// middleware 是个单向链表
type middleware struct {
    handler Handler
    next    *middleware
}

// Negroni
type Negroni struct {
    middleware middleware // 单向链表
    handlers   []Handler // 用于存储所有传入的 handler
}

// New 就是用来构建 middleware 链表的方法
func New(handlers ...Handler) *Negroni {
    return &Negroni{
        handlers:   handlers,
        middleware: build(handlers),
    }
}
```

这里把传入的 `handlers` 保存并传给了 `build` 方法.

## 构建链表

```go
// voidMiddleware 链表的终点
func voidMiddleware() middleware {
    return middleware{
        HandlerFunc(func(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc) {}),
        &middleware{},
    }
}

// build 递归构建 middleware, 最终返回一个完整的链表
func build(handlers []Handler) middleware {
    var next middleware

    switch {
    case len(handlers) == 0:
        return voidMiddleware()
    case len(handlers) > 1:
        next = build(handlers[1:])
    default:
        next = voidMiddleware()
    }

    return middleware{handlers[0], &next}
}
```

## Use实现

`Use` 本质上就是就是重新构建链表的过程

`UseFunc`, `UseHandler`, `UseHandlerFunc` 本质上就是将 `http.Handler` 转换为 `negroni.Handler` 的过程

```go
// Use adds a Handler onto the middleware stack. Handlers are invoked in the order they are added to a Negroni.
func (n *Negroni) Use(handler Handler) {
    if handler == nil {
        panic("handler cannot be nil")
    }

    n.handlers = append(n.handlers, handler)
    n.middleware = build(n.handlers)
}

// UseFunc adds a Negroni-style handler function onto the middleware stack.
func (n *Negroni) UseFunc(handlerFunc func(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc)) {
    n.Use(HandlerFunc(handlerFunc))
}

// UseHandler adds a http.Handler onto the middleware stack. Handlers are invoked in the order they are added to a Negroni.
func (n *Negroni) UseHandler(handler http.Handler) {
    n.Use(Wrap(handler))
}

// UseHandlerFunc adds a http.HandlerFunc-style handler function onto the middleware stack.
func (n *Negroni) UseHandlerFunc(handlerFunc func(rw http.ResponseWriter, r *http.Request)) {
    n.UseHandler(http.HandlerFunc(handlerFunc))
}

func Wrap(handler http.Handler) Handler {
    return HandlerFunc(func(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
        handler.ServeHTTP(rw, r)
        next(rw, r)
    })
}
```

## Run

运行!!!

最终调用了标准库中的 `http.ListenAndServe`, 证明 `Negroni` 实现了标准库的 `http.Handler` 接口, 形成了链表调用

所以 `handler` 的顺序很重要, 一般 `mux` 路由, 都是在最后访入

```go
// middleware 实现了 `http.Handler` 接口
func (m middleware) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
    m.handler.ServeHTTP(rw, r, m.next.ServeHTTP)
}

// Negroni 实现了 `http.Handler` 接口
func (n *Negroni) ServeHTTP(rw http.ResponseWriter, r *http.Request) {
    n.middleware.ServeHTTP(NewResponseWriter(rw), r)
}

func (n *Negroni) Run(addr ...string) {
    l := log.New(os.Stdout, "[negroni] ", 0)
    finalAddr := detectAddress(addr...)
    l.Printf("listening on %s", finalAddr)
    l.Fatal(http.ListenAndServe(finalAddr, n))
}
```
