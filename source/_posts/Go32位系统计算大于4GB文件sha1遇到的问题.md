---
title: Go32位操作系统计算大于4GB文件sha1遇到的问题
date: 2017-11-25 23:11:39
---


文件大于 `4GB` 以下方法一定行不通, 32位操作系统 最大的寻址空间就是 `4GB`.

```go
package main

import (
	"crypto/sha1"
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	bytes, err := ioutil.ReadFile("file.txt")
	if err != nil {
		log.Fatal(err)
	}

	h := sha1.New()
	h.Write(bytes)

	fmt.Printf("% x", h.Sum(nil))
}
```

以下方法可以算出大于 `4GB` 文件的 sha1, 但是如果直接表面理解代码, 给人的感觉是无法运行的.

`io.Copy(h, f)` 这里给人的感觉也是一次性读取文件到 `h` 变量中, "给人一种把 整个文件读取到内存的感觉". 

```go
package main

import (
	"crypto/sha1"
	"fmt"
	"io"
	"log"
	"os"
)

func main() {
	f, err := os.Open("file.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	h := sha1.New()
	if _, err := io.Copy(h, f); err != nil {
		log.Fatal(err)
	}

	fmt.Printf("% x", h.Sum(nil))
}
```


## 详解

跟踪代码 `sha1.New()` 找到  `sha1` 的 `Write` 方法实现.

`io.Copy(h, f)` 会使用这个  `Write` 方法.

```go
func (d *digest) Write(p []byte) (nn int, err error) {
	nn = len(p)
    d.len += uint64(nn)
    // 这里 d.nx 大于 0 的时候 进入进行处理数据.
	if d.nx > 0 {
		n := copy(d.x[d.nx:], p)
		d.nx += n
		if d.nx == chunk {
            // 处理. '具体不知道怎么实现的.. 没研究过.'
            block(d, d.x[:])
            // 但是这里处理完毕后会 清空 d.nx
            // 所以这里的 Write 函数其实已经在处理 sha1 了 
            // 并没有多少实际的内存占用
			d.nx = 0
		}
		p = p[n:]
    }
    
	if len(p) >= chunk {
		n := len(p) &^ (chunk - 1)
		block(d, p[:n])
		p = p[n:]
	}
	if len(p) > 0 {
		d.nx = copy(d.x[:], p)
	}
	return
}
```


