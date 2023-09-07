---
categories:
- 学习
date: "2019-05-16"
tags:
- Go
title: Go HTTP POST 附件
---

前段时间为了使用 `adb` 进行钉钉打卡, 写了个 `Go` 的程序, 想着万一没打上怎么办, 不如截个图发给自己(现在以 root, 辣鸡钉钉), 文章只为了记录一下实现.

```go
// curl -X POST https://example.com/sendPhoto -F photo=@./screen.png

// 以下代码是根据以上 curl 命令的实现

buf := &bytes.Buffer{}
mu := multipart.NewWriter(buf)

part, err := mu.CreatePart(textproto.MIMEHeader{
        "Content-Disposition": []string{`form-data; name="photo"; filename="screen.png"`},
        "Content-Type":[]string{"application/octet-stream"},
    })
checkError(err)

fp, _ := os.Open("/home/mioto/screen.png")
io.Copy(part, fp)
mu.Close()

req, err := http.NewRequest(http.MethodPost, "https://example.com/sendPhoto", bf)
checkError(err)
req.Header.Set("Content-Type", mu.FormDataContentType())

res, err := http.DefaultClient.Do(req)
checkError(err)
```
