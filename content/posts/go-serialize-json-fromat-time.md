---
categories:
- 学习
date: "2018-11-25 19:46:00"
tags:
- Go
title: Go反序列化JSON格式化时间
---

默认得到的序列化后的结果是 `{"t":"2018-11-25T20:04:51.362485618+08:00"}`, 但如果我想得到 `{"t":"2018-11-25 20:04:51"}` 该怎么办呢?

## 方法一

实现 `MarshalJSON` 接口, 同时可能也需要反序列化, 所以还需要实现 `UnmarshalJSON`, 以下代码为实现

```golang
package main

import (
    "encoding/json"
    "fmt"
    "time"
)

type Time struct {
    T time.Time `json:"t,omitempty"`
}

func (t *Time) MarshalJSON() ([]byte, error) {
    type alias Time

    return json.Marshal(struct {
        *alias
        T string `json:"t,omitempty"`
    }{
        alias: (*alias)(t),
        T:     t.T.Format("2006-01-02 15:04:05"),
    })
}

func (t *Time) UnmarshalJSON(data []byte) error {
    type alias Time

    tmp := &struct {
        *alias
        T string `json:"t,omitempty"`
    }{
        alias: (*alias)(t),
    }

    err := json.Unmarshal(data, tmp)
    if err != nil {
        return err
    }

    t.T, err = time.Parse(`2006-01-02 15:04:05`, tmp.T)
    if err != nil {
        return err
    }

    return nil
}
func main() {
    t := &Time{
        T: time.Now(),
    }

    tBytes, _ := json.Marshal(t)
    fmt.Println(string(tBytes))

    t = &Time{}

    _ = json.Unmarshal(tBytes, t)

    fmt.Println(t.T)
}

// output:
//
// {"t":"2018-11-25 20:17:53"}
// 2018-11-25 21:03:35 +0000 UTC
```

## 方法二

不使用 `time.Time`, 而是自己重新定义一个时间类型, 例如 `JSONTime`, 并实现它的 `MarshalJSON` `UnmarshalJSON` 接口, 这样做的好处是 所有都通用, 不需要在用到的类型中反复实现 这两个接口, 以下为实现

```golang
package main

import (
    "encoding/json"
    "fmt"
    "time"
)

type JSONTime struct {
    time.Time
}

func (t *JSONTime) MarshalJSON() ([]byte, error) {
    return []byte(fmt.Sprintf(`"%s"`, t.Format("2006-01-02 15:04:05"))), nil
}

func (t *JSONTime) UnmarshalJSON(data []byte) error {
    var err error

    t.Time, err = time.Parse(`"2006-01-02 15:04:05"`, string(data))
    if err != nil {
        return err
    }

    return nil
}

type Time struct {
    T JSONTime `json:"t,omitempty"`
}

func main() {
    t := &Time{
        T: JSONTime{time.Now()},
    }

    tBytes, _ := json.Marshal(t)
    fmt.Println(string(tBytes))

    t = &Time{}

    _ = json.Unmarshal(tBytes, t)

    fmt.Println(t.T)
}

// output:
//
// {"t":"2018-11-25 21:14:33"}
// 2018-11-25 21:14:33 +0000 UTC
```

## 参考

- <https://stackoverflow.com/questions/23695479/format-timestamp-in-outgoing-json-in-golang>
- <http://choly.ca/post/go-json-marshalling>
