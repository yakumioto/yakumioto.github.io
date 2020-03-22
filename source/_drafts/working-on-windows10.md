---
title: "基于 Windows 的开发环境"
date: 2020-01-05
tags:
  - Go
  - Life
---

换电脑啦！！！退役了用了 6 年的笔记本！！！由于未知错误原因导致无法安装 `Manjaro Linux`，所以决定尝试使用 `Windows` 进行开发。

由于最开始并没有考虑使用 `Windows` 所以显卡选择比较随意 `GTX 1660 Super`，导致无法玩大作，后悔啊！！！

目前的开发工具主要是：

- JetBrains Goland
- Microsoft VSCode （主要用来编辑一些非项目的文件，如 Terminal 的配置文件等）
- Windows Terminal （主要用于打开 WSL2 子系统的，偶尔用来开 PowerShell）
- Windows Ubuntu WSL2 （用来 编译，调试 项目，启停 docker）
- Docker For Windows （WSL2 中操作 docker 容器 都会启动在这个里面）
- Chocolatey （类似 Linux 中的包管理工具，如 Ubuntu 的 apt）
- VirtualBox （甲骨文的虚拟机软件，如创建一个 Kubernetes 集群什么的）
- Vagrant （虚拟机管理工具，如用于一键启动 Kubernetes 集群）
- Putty （SSH 客户端）

以上就是我目前主要用到的开发工具。

## Chocolatey

<https://chocolatey.org/>

无意中接触到的一个工具，很对胃口所以就决定尝试一下了。

安装也很简单，以管理员模式启动 `PowerShell.exe`，然后执行一下命令就可以了。

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

常用的命令

```powershell
choco -h                  # 查看帮助
choco <command> -h        # 查看相应命令的帮助
choco install <package>   # 安装软件包
choco search <filter>     # 搜索软件包
choco upgrade <package>   # 升级软件包
choco uninstall <package> # 卸载软件包
choco list --local-only   # 列出本地安装的软件包
```

以下是我的常用软件

```powershell
choco install -y ccleaner `
    golang `
    googlechrome `
    putty `
    vagrant `
    vim `
    virtualbox `
    virtualbox.extensionpack `
    visualstudiocode `
    wget `
    winrar `
    wireshark
```

## Terminal

从 `Microsoft Store` 中下载安装，颜值不错，但还是需要一些调整。

```json
{
    "profiles":
    {
        "defaults":
        {
            // Put settings here that you want to apply to all profiles
            "fontFace": "Monaco",             // Monaco 字体，苹果里面的我觉的好看就一直再用
            "fontSize": 11,                   // 字体大小
            "colorScheme" : "Solarized Dark", // 终端配色
            "cursorShape": "filledBox",       // 光标样式
            "useAcrylic": true,               // 毛玻璃效果
            "acrylicOpacity": 0.5             // 模糊度
        }
    }
}
```

[Terminal]("images/working-on-windows10/Terminal.png")
