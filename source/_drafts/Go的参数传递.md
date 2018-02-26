---
title: "Go 的参数传递"
date: 2018-02-26 12:18:14
tags:
  - Go
---

`Go` 所有的参数传递均为值传递, 这句话也是理解下面讲解的基础

<!--more-->

## 值传递

值传递: 函数传参总是原来数据的拷贝

```Go
// https://play.golang.org/p/CM4c3un3WXP
package main

import "fmt"

func main() {
	i := 1
	fmt.Printf("i的地址: %p\n", &i)
	modify(i)
	fmt.Printf("i的值: %d\n", i)
}

func modify(data int) {
	fmt.Printf("data的地址: %p\n", &data)
	data = 2
}

// 结果
// i的地址: 0x10414020
// data的地址: 0x10414024
// i的值: 1
```

以上是一个很典型的值传递, 所以也不用讲解了. 

```go
// https://play.golang.org/p/7XIueCCccoh
package main

import "fmt"

func main() {
	i := 1
	pi := &i
	fmt.Printf("pi的值:%p, pi的地址:%p\n", pi, &pi)
	modify(&i)
	fmt.Printf("i的值: %d\n", i)
}

func modify(data *int) {
	fmt.Printf("data的值:%p, data的地址:%p\n", data, &data)
	*data = 2
}

// 结果
// pi的值:0x10414020, pi的地址:0x1040c138
// data的值:0x10414020, data的地址:0x1040c148
// i的值: 2
```