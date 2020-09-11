# naive.sh

## 设计说明

我写它就是用来自动更新 NaiveProxy。
后来我想了想，不如干脆把功能写完整发上来吧？于是就有了 naive.sh。
它不会像[某脚本](https://github.com/233boy/v2ray)一样搞墙外墙，且不会保存在本地以避免产生垃圾 & 确保你每次使用都是最新版本。

## 要求

Linux, x86 或 x86_64
以 root 运行
已安装 wget 和 libnss3
没了。它只做它该做的事，依赖什么的暂时就请自己解决吧。

## 如何使用

``` bash
bash <(wget -qO- https://git.io/naive.sh) #正常模式
bash <(wget -qO- https://git.io/naive.sh) update #自动更新naiveproxy
```

## 待做

- 快速安装 & 自动配置 Caddy v2 + forwardproxy
- 支持 linux-arm, linux-arm64
- 包管理器为 pacman, apt, yum 其一时自动安装依赖

## 灵感

- [yeyingorg/bbr2.sh](https://github.com/yeyingorg/bbr2.sh)
- [teddysun/shadowsocks_install](https://github.com/teddysun/shadowsocks_install)

## 许可证

Copyright © 2020 Ai Hoshikawa <kwa@kwaa.dev>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the [COPYING](https://github.com/kwaa/m/blob/master/COPYING) file for more details.
