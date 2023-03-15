---
categories:
- 学习
date: "2021-01-19T17:23:23+08:00"
tags:
- Go
- Assembly
title: Plan9 汇编入门讲解
---

为什么要看 Plan9 汇编？如果你是 Go 开发者，去学习和理解一下 Plan9 是很有必要的，因为它可以解决你对一段代码的理解（为什么这样不行？那样却可以？）。

Plan9 不同于 AT&T 和 Intel 汇编器，但是懂这两个汇编语法的话对理解 Plan9 还是有很大帮助的。

## 疑惑

```go
// 为什么这个函数的返回值会是 -1
func demo1() int {
	ret := -1
	defer func() {
		ret = 1
	}()
	return ret
}
// output: -1


// 为什么这个函数的返回值会是 1
func demo2() (ret int) {
	defer func() {
		ret = 1
	}()
	return ret
}
// output: 1
```

相信大部分人都看过类似的解答，demo1 中是临时变量导致的，而 demo2 中没有临时变量，这是最终结果。

在汇编层面到底做了什么？本文将会探讨这个问题。（本文所使用的平台是 MacOS AMD64）不同的平台指令集和寄存器都不一样。

## 基础

### 通用寄存器

下面是通用通用寄存器的名字在 IA64 和 plan9 中的对应关系：

| IA64  | RAX  | RBX  | RCX  | RDX  | RDI  | RSI  | RBP  | RSP  | R8   | R9   | R10  | R11  | R12  | R13  | R14  | RIP  |
| ----- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| Plan9 | AX   | BX   | CX   | DX   | DI   | SI   | BP   | SP   | R8   | R9   | R10  | R11  | R12  | R13  | R14  | PC   |

应用代码层面会用到的通用寄存器主要是： AX, BX, CX, DX, DI, SI, R8~R15 这 14 个寄存器，虽然 BP 和 SP 也可以用，不过 BP 和 SP 会被用来管理栈顶和栈底，最好不要拿来进行运算。

Plan9 汇编的操作数方向和 Intel 汇编相反的，与 AT&T 类似。

### 伪寄存器

Go 汇编引入了 4 个伪寄存器，官方定义如下：

- FP: Frame pointer: arguments and locals.
- PC: Program counter: jumps and branches.
- SB: Static base pointer: global symbols.
- SP: Stack pointer: top of stack.

以下针对 FP，SP 做一些描述：

- FP：使用形式如 `symbol+offset(FP)` 的方式，引用函数的输入参数。eg：`first_arg+0(FP)`，`second_arg+8(FP)`
- SP：SP 是有对应的寄存器的，所以区分 SP 到底是指硬件 SP 还是指虚拟寄存器，需要以特定的格式来区分。eg：`symbol+offset(SP)` 则表示伪寄存器 SP。eg：`offset(SP)` 则表示硬件 SP。

### 变量声明

使用 DATA 结合 GLOBL 来定义一个变量。

```go
DATA	symbol+offset(SB)/width, value
```

使用 GLOBL 指令将变量声明为 global，额外接收两个参数，一个是 flag，另一个是变量的总大小。

```go
GLOBL divtab(SB), RODATA, $8
```

GLOBL 必须跟在 DATA 指令之后，下面是一个定义了多个 readonly 的全局变量的完整例子：

```go
DATA pi+0(SB)/8, $3.1415926
GLOBL pi(SB), RODATA, $8
```

在全局变量中定义数组，字符串，这时候就需要添加 `<>` ，`<>` 符号可以使变量使用偏移量操作。例子：

```go
DATA array<>+0(SB)/8, $1
DATA array<>+8(SB)/8, $2
```

**通常建议直接使用 `<>` 进行变量声明**。

### 函数声明

```go
// 函数声明
// 该声明一般写在任意一个 .go 文件中，例如：add.go
func add(a, b int) int

// 函数实现
// 该实现一般写在与声明同名的 _{Arch}.s 文件中，例如：add_amd64.s
TEXT pkgname·add(SB), NOSPLIT, $0-16
    MOVQ a+0(FP), AX
    MOVQ a+8(FP), BX
    ADDQ AX, BX
    MOVQ BX, ret+16(FP)
    RET
```

`pkgname` 可以不写，一般都是不写的，可以参考 go 的源码， 另外 add 前的 `·` 不是 `.`

```text
                            参数及返回值大小
                                 | 
 TEXT pkgname·add(SB),NOSPLIT,$0-16
         |     |               |
        包名  函数名    栈帧大小(局部变量+可能需要的额外调用函数的参数空间的总大小，
                               但不包括调用其它函数时的 ret address 的大小)
```

以上使用的 `RODATA`，`NOSPLIT`  flag，还有其他的值，可以参考：<https://golang.org/doc/asm#directives>，

**务必注意**：对于编译输出 go tool compile -S / go tool objdump 的代码来讲，目前所有的 SP 都是硬件寄存器 SP，无论是否带 symbol。

以下为上图的栈结构示意图，由于没有临时变量，所以伪 SP 和 硬件 SP 在同一个位置。 

```text
+------------------+
| return parameter |
+------------------+
|   parameter b    | 
+------------------+
|   parameter a    | <-- pseudo FP addr
+------------------+
| caller ret addr  | <-- pseudo SP addr and hardware SP addr
+------------------+
```

## 分析

### 编译 / 反编译

很多时候我们无法确定一块代码是如何执行的，需要通过生成汇编、反汇编来研究

```go
// 编译
go build -gcflags="-S"
go tool compile -S hello.go
go tool compile -N -S hello.go // 禁止优化
// 反编译
go tool objdump <binary>
```

基础已经介绍的差不多了，接下来就是深究这两段代码的区别。

```go
// go tool compile -S demo1.go
func demo1() int {
	ret := -1
	defer func() {
		ret = 1
	}()
	return ret
}

// 编译的汇编 demo1 部分代码 
"".demo1 STEXT size=158 args=0x8 locals=0x30
        0x0000 00000 (.\scratch.go:5)   TEXT    "".demo1(SB), ABIInternal, $48-8

        // 栈的初始化操作，以及 GC相关的标记等等操作，有兴趣的可以自己研究以下。
        ...
        
        // 15(SP) 不知道为什么要操作这个，望大佬解释，本人猜测可能跟 deferreturn 有关。
        0x002c 00044 (.\scratch.go:5)   MOVB    $0, ""..autotmp_3+15(SP)
        
        // 这里对 56(SP) 地址进行了赋值操作写了个 0，这个位置其实是返回值地址
        0x0031 00049 (.\scratch.go:5)   MOVQ    $0, "".~r0+56(SP)
        
        // 16(SP) 临时变量 ret，将 -1 写入到了栈中。
        0x003a 00058 (.\scratch.go:6)   MOVQ    $-1, "".ret+16(SP)

        // 猜测与 deferreturn 有关。
        0x0043 00067 (.\scratch.go:7)   LEAQ    "".demo1.func1·f(SB), AX
        0x004a 00074 (.\scratch.go:7)   MOVQ    AX, ""..autotmp_4+32(SP)

        // 将 16(SP) 的地址给了 AX 寄存器，这个地址里存的是 -1
        0x004f 00079 (.\scratch.go:7)   LEAQ    "".ret+16(SP), AX

        // 将 AX 寄存器里的 16(SP) 的地址给了 24(SP)
        0x0054 00084 (.\scratch.go:7)   MOVQ    AX, ""..autotmp_5+24(SP)
        0x0059 00089 (.\scratch.go:7)   MOVB    $1, ""..autotmp_3+15(SP)

        // 将 16(SP) 的值给了 AX 寄存器，这个地址里存的是 -1
        0x005e 00094 (.\scratch.go:10)  MOVQ    "".ret+16(SP), AX
        
        // 将 AX 的值给了 56(SP), 56(SP) 上面说过了是返回值地址， 所以当前的返回值是 -1
        // 这里也是最后一次操作 56(SP)，所以最终的返回值是 -1
        0x0063 00099 (.\scratch.go:10)  MOVQ    AX, "".~r0+56(SP)
        0x0068 00104 (.\scratch.go:10)  MOVB    $0, ""..autotmp_3+15(SP)

        // 24(SP) 的值给了 AX，24(SP) 存储的是 16(SP) 的地址， 也就是临时变量的地址
        0x006d 00109 (.\scratch.go:10)  MOVQ    ""..autotmp_5+24(SP), AX

        // 将 AX 的值给了  0(SP)， 也就是将 16(SP) 的地址给了 0(SP)
        // 这里可以 0(SP) 为调用 demo1.func1 的入参
        0x0072 00114 (.\scratch.go:10)  MOVQ    AX, (SP)
        0x0076 00118 (.\scratch.go:10)  PCDATA  $1, $1

        // 调用 demo1.func1
        0x0076 00118 (.\scratch.go:10)  CALL    "".demo1.func1(SB)
        0x007b 00123 (.\scratch.go:10)  MOVQ    40(SP), BP
        0x0080 00128 (.\scratch.go:10)  ADDQ    $48, SP
        0x0084 00132 (.\scratch.go:10)  RET
        0x0085 00133 (.\scratch.go:10)  CALL    runtime.deferreturn(SB)
        0x008a 00138 (.\scratch.go:10)  MOVQ    40(SP), BP
        0x008f 00143 (.\scratch.go:10)  ADDQ    $48, SP
        0x0093 00147 (.\scratch.go:10)  RET
        0x0094 00148 (.\scratch.go:10)  NOP
        0x0094 00148 (.\scratch.go:5)   PCDATA  $1, $-1
        0x0094 00148 (.\scratch.go:5)   PCDATA  $0, $-2
        0x0094 00148 (.\scratch.go:5)   CALL    runtime.morestack_noctxt(SB)
        0x0099 00153 (.\scratch.go:5)   PCDATA  $0, $-1
        0x0099 00153 (.\scratch.go:5)   JMP     0

"".demo1.func1 STEXT nosplit size=13 args=0x8 locals=0x0
        // 这里的 $0-8 就是只有一个参数没有返回值， go 代码中 defer 后面的函数
        0x0000 00000 (.\scratch.go:8)   TEXT    "".demo1.func1(SB), NOSPLIT|ABIInternal, $0-8
        0x0000 00000 (.\scratch.go:8)   FUNCDATA        $0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
        0x0000 00000 (.\scratch.go:8)   FUNCDATA        $1, gclocals·69c1753bd5f81501d95132d08af04464(SB)

        // 将 8(SP) 的值给了 AX 寄存器，也就是将 16(SP) 的地址给了 AX
        0x0000 00000 (.\scratch.go:9)   MOVQ    "".&ret+8(SP), AX

        // 将 1 给了 AX 寄存器保存的地址的位置上。这个操作像 *a = 1
        0x0005 00005 (.\scratch.go:9)   MOVQ    $1, (AX)
        0x000c 00012 (.\scratch.go:10)  RET

```

这里有了第一段汇编的讲解就不做特别具体的描述了，只标注重点关注的地方。

```go
// go tool compile -S demo2.go
func demo2() (ret int) {
	defer func() {
		ret = 1
	}()
	return ret
}

// 编译的汇编 demo2 部分代码 
"".demo2 STEXT size=138 args=0x8 locals=0x28
        0x0000 00000 (.\scratch.go:6)   TEXT    "".demo2(SB), ABIInternal, $40-8
        ...
        0x002c 00044 (.\scratch.go:6)   MOVB    $0, ""..autotmp_2+15(SP)
        0x0031 00049 (.\scratch.go:6)   MOVQ    $0, "".ret+48(SP)
        0x003a 00058 (.\scratch.go:7)   LEAQ    "".demo2.func1·f(SB), AX
        0x0041 00065 (.\scratch.go:7)   MOVQ    AX, ""..autotmp_3+24(SP)
        
        // 将返回值地址给了 AX 寄存器
        0x0046 00070 (.\scratch.go:7)   LEAQ    "".ret+48(SP), AX
        
        // 返回值地址给了 16(SP)
        0x004b 00075 (.\scratch.go:7)   MOVQ    AX, ""..autotmp_4+16(SP)
        0x0050 00080 (.\scratch.go:10)  MOVB    $0, ""..autotmp_2+15(SP)

        // 又将 返回值地址给了 AX 寄存器
        0x0055 00085 (.\scratch.go:10)  MOVQ    ""..autotmp_4+16(SP), AX

        // 将返回值地址给了 0(SP)
        // 这里可以 0(SP) 为调用 demo2.func1 的入参
        0x005a 00090 (.\scratch.go:10)  MOVQ    AX, (SP)
        0x005e 00094 (.\scratch.go:10)  PCDATA  $1, $1
        0x005e 00094 (.\scratch.go:10)  NOP

        // 调用了 demo2.func1
        0x0060 00096 (.\scratch.go:10)  CALL    "".demo2.func1(SB)
        0x0065 00101 (.\scratch.go:10)  MOVQ    32(SP), BP
        0x006a 00106 (.\scratch.go:10)  ADDQ    $40, SP
        0x006e 00110 (.\scratch.go:10)  RET
        0x006f 00111 (.\scratch.go:10)  CALL    runtime.deferreturn(SB)
        0x0074 00116 (.\scratch.go:10)  MOVQ    32(SP), BP
        0x0079 00121 (.\scratch.go:10)  ADDQ    $40, SP
        0x007d 00125 (.\scratch.go:10)  RET
        0x007e 00126 (.\scratch.go:10)  NOP
        0x007e 00126 (.\scratch.go:6)   PCDATA  $1, $-1
        0x007e 00126 (.\scratch.go:6)   PCDATA  $0, $-2
        0x007e 00126 (.\scratch.go:6)   NOP
        0x0080 00128 (.\scratch.go:6)   CALL    runtime.morestack_noctxt(SB)
        0x0085 00133 (.\scratch.go:6)   PCDATA  $0, $-1
        0x0085 00133 (.\scratch.go:6)   JMP     0

"".demo2.func1 STEXT nosplit size=13 args=0x8 locals=0x0
        0x0000 00000 (.\scratch.go:7)   TEXT    "".demo2.func1(SB), NOSPLIT|ABIInternal, $0-8
        0x0000 00000 (.\scratch.go:7)   FUNCDATA        $0, gclocals·1a65e721a2ccc325b382662e7ffee780(SB)
        0x0000 00000 (.\scratch.go:7)   FUNCDATA        $1, gclocals·69c1753bd5f81501d95132d08af04464(SB)
        0x0000 00000 (.\scratch.go:8)   MOVQ    "".&ret+8(SP), AX
        // 这里将返回值的值修改成了 1
        0x0005 00005 (.\scratch.go:8)   MOVQ    $1, (AX)
        0x000c 00012 (.\scratch.go:9)   RET

```

以上就是两个方法的汇编源码解析，从两个栗子中可以得到结果。

demo1 中的 ret 是临时变量，虽然 defer 确实改了 ret 的值，但这个值跟返回值没一毛钱关系，而且在汇编中 demo1 的返回值在还没调用 demo1.func1 的时候就已经确定了，所以 demo1 返回了 -1。

demo2 中的 ret 则直接指向了返回值的地址，defer 也改了返回值的值， 所以 demo2 就返回了 1。

## 参考

1. <https://golang.org/doc/asm#directives>
2. <https://xargin.com/plan9-assembly/>
3. <https://www.doxsey.net/blog/go-and-assembly>
4. <https://davidwong.fr/goasm/>