# naive.sh

## 设计说明

我写它就是用来自动更新 Naiveproxy。
后来我想了想，不如干脆把功能写完整发上来吧？然后就有了 naive.sh。
它不会像[某脚本](https://github.com/233boy/v2ray)一样搞墙外墙，且不会保存在本地以避免产生垃圾 & 确保你每次使用都是最新版本。

## 要求

Linux, x86 / x86_64 / arm / arm64 (arm/arm64 未测试)
以 root 运行
已安装 wget
Debian / Ubuntu / Arch 会自动安装依赖，其他发行版请手动安装或提交 Pull Request。

## 功能

安装，更新和卸载 naiveproxy 客户端 / 服务端
编辑配置文件请用 nano / vim / emacs
管理请用 systemctl
自动更新请用 crontab 定期执行此脚本（由于服务端为 caddy，目前没有检测版本更新的合适方式；所以 update server 指令不会对比版本，每次都会重新进行编译）

## 如何使用

> 注意：参数可能随更新而改变；v210211 版本未经测试，如有 bug 请提交 issue

```bash
bash <(wget -qO- https://git.io/naive.sh) #面板模式
bash <(wget -qO- https://git.io/naive.sh) update client #自动更新客户端, 旧版的仅 update 依然可用
```

你可以单命令安装服务端：

```bash
bash <(wget -qO- https://git.io/naive.sh) example.com auto # 使用自动生成的邮箱, user, pass, probe_resistance 进行配置
bash <(wget -qO- https://git.io/naive.sh) example.com me@example.com username password bing.com bing.com h3 # 使用输入的邮箱, user, pass 进行配置，伪装并反代 bing.com, 开启 HTTP3
```

详细说明：

- $1: 域名，需要以 A 或 AAAA 记录绑定到主机 IP。
- $2: 邮箱或 auto, 若为 auto 则自动生成配置。
- $3: 用户名, 当 $2 为 auto 时功能等同 $7。
- $4: 密码
- $5: 伪装域名
- $6: 反向代理. 不为空或 false 即启用。
- $7: HTTP3，不为空即启用。

## 待做

- 下载二进制 caddy 文件避免编译过程
- 通过 Docker 安装服务端

## 灵感

- [yeyingorg/bbr2.sh](https://github.com/yeyingorg/bbr2.sh)
- [teddysun/shadowsocks_install](https://github.com/teddysun/shadowsocks_install)

## 许可证

Copyright © 2020 Ai Hoshikawa <kwa@kwaa.dev>
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the [COPYING](https://github.com/kwaa/m/blob/master/COPYING) file for more details.
