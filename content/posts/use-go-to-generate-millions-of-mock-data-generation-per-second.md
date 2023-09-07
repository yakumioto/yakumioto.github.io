---
categories:
- 学习
date: "2021-09-25T10:30:23+08:00"
tags:
- Go
title: 使用 Go 语言每秒百万量级的模拟数据生成优化总结
---

本文旨在深入研究如何使用Go语言优化模拟数据生成性能。我们将介绍三个不同版本的代码实现，并详细分析它们的性能和优点。

## 版本一：基础实现

首先，让我们来看看第一个版本的代码，这是一个基础实现，没有引入并发。以下是版本一的核心代码：

```go
func randomVersion1(labels []int) *strings.Builder {
    str := &strings.Builder{}
    for i := 0; i < len(labels); i++ {
        switch labels[i] {
        case 0:
            str.WriteString(strconv.Itoa(rand.Intn(2) - 1))
        case 1:
            str.WriteString(fmt.Sprintf("%.8f", 0.1+rand.Float64()*(1-0.1)))
        }

        if i < len(labels)-1 {
            str.WriteString(",")
        }
    }
    return str
}

func TestVersion1(t *testing.T) {
    f, _ := os.OpenFile(filename, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
    buf := bufio.NewWriter(f)
    s := time.Now()
    buf.WriteString(fmt.Sprintf("%s\n", header))

    for i := 0; i < 1000000; i++ {
        buf.WriteString(fmt.Sprintf("%d,%s\n", i, randomVersion1(labels).String()))
    }
    fmt.Println("version1 use time: ", time.Since(s))
}
```

### 版本一的特点：

- 使用 `strings.Builder` 和 `bufio.Writer` 进行字符串和文件操作，以提高性能。
- 利用 `os.OpenFile` 和 `bufio.NewWriter` 来进行文件操作，确保高效且安全。

## 版本二：引入并发

接下来，我们将介绍版本二的代码，它引入了并发处理，通过协程和通道来提高性能。以下是版本二的核心代码示例：

```go
func randomVersion2(labels []int, columnCh chan *strings.Builder) {
	str := &strings.Builder{}
	for i := 0; i < len(labels); i++ {
		switch labels[i] {
		case 0:
			str.WriteString(strconv.Itoa(rand.Intn(2) - 1))
		case 1:
			str.WriteString(fmt.Sprintf("%.8f", 0.1+rand.Float64()*(1-0.1)))
		}

		if i < len(labels)-1 {
			str.WriteString(",")
		}
	}

	columnCh <- str
}

func TestVersion2(t *testing.T) {
	f, _ := os.OpenFile(filename, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	buf := bufio.NewWriter(f)
	s := time.Now()
	buf.WriteString(fmt.Sprintf("%s\n", header))

	columCh := make(chan *strings.Builder, 2000)
	countCh := make(chan int)

	wg := sync.WaitGroup{}

	worker := func(n chan int) {
		for {
			_, ok := <-n
			if !ok {
				wg.Done()
				return
			}
			randomVersion2(labels, columCh)
		}
	}

	for i := 0; i < runtime.NumCPU()*2; i++ {
		wg.Add(1)
		go worker(countCh)
	}

	go func() {
		for i := 0; i < 1000000; i++ {
			countCh <- i
		}
		close(countCh)
	}()

	for i := 0; i < 1000000; i++ {
		colum, ok := <-columCh
		if !ok {
			return
		}
		buf.WriteString(fmt.Sprintf("%d,%s\n", i, colum.String()))
	}

	fmt.Println("version2 use time: ", time.Since(s))
}
```

### 版本二的优势

- **卓越的性能**：通过并发，版本二在多核 CPU 上表现出色。
- **最大程度地利用系统资源**：根据CPU核心数创建工作线程，更有效地管理资源。
- **优越的扩展性**：使用工作队列和协程模型，易于扩展。
- **精确的任务管理**：结合 `sync.WaitGroup` 和通道，确保任务的准确执行。
- **增强的吞吐量**：通过使用缓冲通道，提高性能。

## 版本三：进一步优化

版本三对性能和内存效率进行了更深层次的优化，引入了自定义随机源和对象池。以下是版本三的核心代码示例：

```go
type randSource struct {
	rand.Source
}

func (r *randSource) Float64() float64 {
	// Change from Go 1 -- make results be uniform.
	return (float64(r.Int63() >> 10)) * (1.0 / 9007199254740992.0)
}

func (r *randSource) Int() int64 {
	// Change from Go 1 -- make results be uniform.
	return r.Int63() % 2
}

func randomVersion2(labels []int, columnCh chan *strings.Builder) {
	str := &strings.Builder{}
	for i := 0; i < len(labels); i++ {
		switch labels[i] {
		case 0:
			str.WriteString(strconv.Itoa(rand.Intn(2) - 1))
		case 1:
			str.WriteString(fmt.Sprintf("%.8f", 0.1+rand.Float64()*(1-0.1)))
		}

		if i < len(labels)-1 {
			str.WriteString(",")
		}
	}

	columnCh <- str
}

func TestVersion3(t *testing.T) {
	poolBuilder := sync.Pool{
		New: func() interface{} {
			return bytes.NewBuffer(make([]byte, 0, 4096))
		},
	}
	poolBuf := sync.Pool{
		New: func() interface{} {
			return make([]byte, 0, 8)
		},
	}

	wg := sync.WaitGroup{}
	count := 1000000
	countCh := make(chan int)
	columCh := make(chan *bytes.Buffer, 2000)

	random := func(labels []int, r *randSource, columCh chan *bytes.Buffer) {
		str := poolBuilder.Get().(*bytes.Buffer)
		buf := poolBuf.Get().([]byte)
		for i := 0; i < len(labels); i++ {
			switch labels[i] {
			case 0:
				str.Write(strconv.AppendInt(buf, r.Int(), 10))
			case 1:
				str.Write(strconv.AppendFloat(buf, r.Float64(), 'f', 8, 64))
			}

			if i < len(labels)-1 {
				str.WriteByte(',')
			}
		}
		poolBuf.Put(buf)
		columCh <- str
	}

	f, _ := os.OpenFile(filename, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	buf := bufio.NewWriter(f)

	s := time.Now()
	buf.WriteString(fmt.Sprintf("%s\n", header))

	worker := func(n chan int) {
		r := &randSource{
			Source: rand.NewSource(rand.Int63()),
		}
		for {
			_, ok := <-n
			if !ok {
				wg.Done()
				return
			}
			random(labels, r, columCh)
		}
	}

	for i := 0; i < runtime.NumCPU()*2; i++ {
		wg.Add(1)
		go worker(countCh)
	}

	for i := 0; i < runtime.NumCPU()*2; i++ {
		wg.Add(1)
		go worker(countCh)
	}

	go func() {
		for i := 0; i < count; i++ {
			countCh <- i
		}
		close(countCh)
	}()

	for i := 0; i < count; i++ {
		colum, ok := <-columCh
		if !ok {
			return
		}
		b := poolBuf.Get().([]byte)
		buf.Write(strconv.AppendInt(b, int64(i), 10))
		buf.WriteByte(',')
		buf.Write(colum.Bytes())
		buf.WriteByte('\n')
		colum.Reset()
		poolBuilder.Put(colum)
		poolBuf.Put(b)
	}

	buf.Flush()
	f.Close()

	fmt.Println("version3 use time:", time.Since(s))
}
```

#### Go代码：`TestVersion3` 函数与 `randomVersion2` 函数的区别和优势

- **减少内存占用**：使用 sync.Pool 重用内存，有效降低GC负担。
- **改进性能**：借助字节操作和缓冲，提高性能。
- **更高的并发性**：通过增加工作线程数量，充分发挥多核CPU的威力。
- **更精确的随机数生成**：自定义随机数源生成更均匀的随机数，无需竞争全局锁。
- **优化的代码结构**：将随机数生成逻辑封装在函数中，提高代码的可维护性和可重用性。
- **更快的数据写入**：借助字节操作和缓冲，提高数据写入速度。
- **全局锁的区别**：在版本三中，我们引入了自定义的 randSource 结构，并重写了 Float64 和 Int 方法，以自定义随机数生成的方式。通过这种方式，我们无需竞争 rand 包的全局锁，从而避免了在多线程环境下可能出现的性能瓶颈。

通过这些改进，`TestVersion3`在性能、内存效率和可扩展性方面都有明显的优势。