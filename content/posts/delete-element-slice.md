---
categories:
- 学习
date: "2020-06-03"
tags:
- Go
title: Go 删除 Slice 中的某一个值
---

## 方法一

优点: 速度最快
缺点: 会导致切片数据顺序改变

```go
a := []string{"A", "B", "C", "D", "E"}
i := 2

a[i] = a[len(a)-1] // 将数组的最后一位赋值给需要删除的 index 上
a = a[:len(a)-1] // 移除掉最后一个没用的数据

// Output:
// [A B E D]
```

## 方法二

优点: 速度会随着切片长度改变
缺点: 保持原有切片顺序

```go
a := []string{"A", "B", "C", "D", "E"}
i := 2

a = append(a[:i], a[i+1:]...)

// Output:
// [A B D E]
```

## Benchmark

```text
goos: linux
goarch: amd64
pkg: github.com/yakumioto/go-example/benchmark/delete-element-slice
Benchmark1
Benchmark1-4    1000000000         0.700 ns/op
Benchmark2
Benchmark2-4    93140385            12.9 ns/op
PASS
ok      github.com/yakumioto/go-example/benchmark/delete-element-slice  4.169s
```

## 参考

1. <https://yourbasic.org/golang/delete-element-slice>
2. <https://blog.golang.org/slices>
