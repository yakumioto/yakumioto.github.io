---
title: 'i3wm 更换默认打开的文件管理器'
date: 2019-04-28 11:00:00
tags:
  - Linux
  - i3wm
  - i3
---

可以通过 `xdg-mime` 来查询当前默认的文件管理器 `xdg-mime query default inode/directory`

```bash
mioto:~/ $ xdg-mime query default inode/directory
visual-studio-code.desktop
```

## 方法一

还是可以通过 `xdg-mime` 来设置默认文件管理器 `xdg-mime default {file manager}.desktop inode/directory`

```bash
mioto:~/ $ xdg-mime default ranger.desktop inode/directory
mioto:~/ $ xdg-mime query default inode/directory
ranger.desktop
```

## 方法二

我记录有2个 `mimeapps.list` 文件修改点

`~/.local/share/applications/mimeapps.list`, `~/.config/mimeapps.list` 选一个修改(没有添加) `inode/directory=ranger.desktop`

但是我的系统 `Manjaro-I3` 使用的是 `mimeapps.list`, 所以有针对性的修改就行