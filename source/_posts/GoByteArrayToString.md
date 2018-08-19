---
title: Go byte 数组转 string
date: 2018-03-11 11:01:03
tags:
  - Go
---

今天遇到个问题, 如何将 `[32]byte` 转 `string`

```go
// https://play.golang.org/p/JkK_B5609GN

func main() {
    hs := sha256.Sum256([]byte("hahaha"))
    fmt.Println(hs)
}

// =====
// [190 23 140 5 67 235 23 245 243 4 48 33 201 229 252 243 2 133 229 87 164 252 48 156 206 151 255 156 166 24 41 18]
```

<!--more-->

## 方法1

直接将 `hs` 转 `slice`, 但是打印出来的是乱码

```go
// https://play.golang.org/p/RH8_iHLuWeg

func main() {
    hs := sha256.Sum256([]byte("hahaha"))
    fmt.Println(string(hs[:]))
}

// =====
// ��C���0!������W��0�Η���)
```

## 方法2

```go
// https://play.golang.org/p/Z1-pU0mjX_B

func main() {
    hs := sha256.Sum256([]byte("hahaha"))
    fmt.Println(fmt.Sprintf("%x", hs))
}

// =====
// be178c0543eb17f5f3043021c9e5fcf30285e557a4fc309cce97ff9ca6182912
```

## 方法3

```go
// https://play.golang.org/p/x8ovK9CkRlG

func main() {
    hs := sha256.Sum256([]byte("hahaha"))
    fmt.Println(hex.EncodeToString(hs[:]))
}

// =====
// be178c0543eb17f5f3043021c9e5fcf30285e557a4fc309cce97ff9ca6182912
```

## 参考

<https://stackoverflow.com/questions/14230145/what-is-the-best-way-to-convert-byte-array-to-string>
