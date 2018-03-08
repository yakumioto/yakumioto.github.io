---
title: Go Slice 原理解析
date: 2018-03-08T15:30:27.000Z
tags:
  - Go
---

今天被一道题目恶心到了, 发现不研究这些东西可能真的活不下去了, 狠下心来读了一个多小时的源码, 写下些自己对 `Slice` 的见解吧.

先说说那个题目.

```go
// https://play.golang.org/p/2fA3BylTgtf

// 请问 s1 和 s2 的值分别是?
func main() {
    s1 := []int{1, 2, 3}
    s2 := s1[:0]

    s2 = append(s2, 4)

    fmt.Println(s1)
    fmt.Println(s2)
}
//==========
// [4 2 3]
// [4]
```

<!-- more -->

# Slice 定义

先看看 `Slice` 在 `Go` 底层的定义

```go
// https://github.com/golang/go/blob/master/src/reflect/value.go#L1806

type sliceHeader struct {
    Data unsafe.Pointer   // Array pointer
    Len  int              // slice length
    Cap  int              // slice capacity
}
```

## 原理讲解

### 第一行

`s1 := []int{1, 2, 3}` 是将 `[1, 2, 3]` 的首地址 存入了 `Data` 中, 设置了 `Len` 为 3, 设置了 `Cap` 为 3.

```go
// https://play.golang.org/p/bjP8BKtwQQl

// 验证代码.
func main() {
    s1 := []int{1, 2, 3}
    // 我们可以先将它转成 *reflect.SliceHeader 类型.
    // *reflect.SliceHeader 定义在: https://github.com/golang/go/blob/master/src/reflect/value.go#L1800
    // 顺带着再说一句 uintptr: uintptr 是整型, 可以足够保存指针的值得范围, 在 32 平台下为 4 字节,在 64 位平台下是 8 字节
    sliceHeader1 := (*reflect.SliceHeader)((unsafe.Pointer)(&s1))
    fmt.Printf("data address: %#0x, len: %d, cap: %d\n", sliceHeader1.Data, sliceHeader1.Len, sliceHeader1.Cap)
}
//===
// data address: 0x10414020, len: 3, cap: 3
```

### 第二行

`s2 := s1[:0]` 是将 `s1` 的 `Data` 中的值, 赋值给了 `s2` 的 `Data` 中, 设置 `Len` 为 0, `s1` 的 `Cap` 赋值给了 `s2` 的 `Cap`.

上面这一段有可能不太好理解, 我直接拿出源码来说.

```go
// https://github.com/golang/go/blob/master/src/reflect/value.go#1559

func (v Value) Slice(i, j int) Value {
    // ... 略过无用代码
    switch kind := v.kind(); kind {
    // ...
    case Slice:
        typ = (*sliceType)(unsafe.Pointer(v.typ))
        s := (*sliceHeader)(v.ptr)
        base = s.Data
        cap = s.Cap
    }
    // ...

    // Declare slice so that gc can see the base pointer in it.
    var x []unsafe.Pointer

    // Reinterpret as *sliceHeader to edit.
    s := (*sliceHeader)(unsafe.Pointer(&x))
    // 这里是给 s2.Len 进行赋值. s1[:0]  i 没有传所以为 0, j 也为 0, 所以 j - i ...
    s.Len = j -
    // 这里是给 s2.Cap 进行赋值. cap 在上面的 case 中 被赋值为 3, 3 - 0  emmm...
    s.Cap = cap - i
    // if 为真
    if cap-i > 0 {
          // 所以这里是给 s2.Data 进行赋值.
          // arrayAt 感觉是对地址进行操作的. 处理方法方法也很神奇..
          s.Data = arrayAt(base, i, typ.elem.Size(), "i < cap")
    } else {
          // do not advance pointer, to avoid pointing beyond end of slice
          s.Data = base
    }
}
```
