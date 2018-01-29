---
title: "使用GoBase64标准包遇到的问题"
date: 2018-01-29 15:53:07
tags:
  - Golang
---

在解析 `jwt` 中的 `Playload` 部分的 `base64` 时遇到了错误.

## 报错代码

```go
enstr := "eyJBY2NvdW50SWQiOiIxIiwiQ2xpZW50IjoiIiwiRW1haWwiOiJ5YWt1Lm1pb3RvQGdtYWlsLmNvbSIsIk1hc3RlckZsYWciOnRydWUsImV4cCI6MTU0ODc0NTY5OSwidHlwZSI6ImVtcGxveWVlcyJ9"
// {"AccountId":"1","Client":"","Email":"yaku.mioto@gmail.com","MasterFlag":true,"exp":1548745699,"type":"employees"}

debytes, err := base64.StdEncoding.DecodeString(enstr)
if err := nil {
  // ...
  // err output: illegal base64 data at input byte xxx
}
// ...
```

<!--more-->

源码: <https://golang.org/src/encoding/base64/base64.go>

```go
const (
	StdPadding rune = '=' // Standard padding character
	NoPadding  rune = -1  // No padding
)

const encodeStd = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
// StdEncoding is the standard base64 encoding, as defined in
// RFC 4648.
var StdEncoding = NewEncoding(encodeStd)

// RawStdEncoding is the standard raw, unpadded base64 encoding,
// as defined in RFC 4648 section 3.2.
// This is the same as StdEncoding but omits padding characters.
var RawStdEncoding = StdEncoding.WithPadding(NoPadding)

// NewEncoding returns a new padded Encoding defined by the given alphabet,
// which must be a 64-byte string that does not contain the padding character
// or CR / LF ('\r', '\n').
// The resulting Encoding uses the default padding character ('='),
// which may be changed or disabled via WithPadding.
func NewEncoding(encoder string) *Encoding {
  // ...
}
```

## 原因

`jwt` 的 `base64` 是去除填充物的, 所以不能使用 `StdEncoding` 应该使用 `RawStdEncoding`

所以代码应该是这样

```go
enstr := "eyJBY2NvdW50SWQiOiIxIiwiQ2xpZW50IjoiIiwiRW1haWwiOiJ5YWt1Lm1pb3RvQGdtYWlsLmNvbSIsIk1hc3RlckZsYWciOnRydWUsImV4cCI6MTU0ODc0NTY5OSwidHlwZSI6ImVtcGxveWVlcyJ9"
// {"AccountId":"1","Client":"","Email":"yaku.mioto@gmail.com","MasterFlag":true,"exp":1548745699,"type":"employees"}

debytes, err := base64.RawStdEncoding.DecodeString(enstr)
if err := nil {
  // ...
  // err output: illegal base64 data at input byte xxx
}
// ...
```

参考: <https://stackoverflow.com/a/42683706/9176562>

