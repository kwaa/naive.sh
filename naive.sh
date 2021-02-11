#!/usr/bin/env bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

if [ $(id -u) != "0" ]; then
    echo "你必须要以 root 身份运行此脚本！"
    exit 1
fi

distro=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

case $(uname -m) in
x86_64)
    arch="x64";;
i*86)
    arch="x86";;
aarch64 | aarch64_be | armv8b | armv8l)
    arch="arm64";;
arm | armv7l | armv6l)
    arch="arm";;
*)
    arch="unknown";;
esac

check_naive_client(){
    while :
        do
            github_version=$(wget --no-check-certificate -qO- https://api.github.com/repos/klzgrad/naiveproxy/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed -e "s/^v//" -e "s/-.$//")
        if [ -n "${github_version}" ]; then
            break
        fi
    done
    if [ "$(command -v /usr/local/bin/naive)" ]; then
        local_version=$(/usr/local/bin/naive --version | sed -e "s/^naive //")
    else
        local_version="未安装"
    fi
}

install_naive_client_before(){
    if [ "$(ldconfig -p | grep libnss3)" == "" ]; then
    case "$distro" in
        debian | ubuntu)
            apt update
            apt install libnss3;;
        arch)
            pacman -S nss;;
        *)
            echo "暂未支持你使用的发行版，请考虑提交 Pull Request 并自行安装依赖：libnss3"
            exit 0;;
    esac
    fi
}

install_naive_client(){
    cd /tmp
    wget https://github.com/klzgrad/naiveproxy/releases/download/v${github_version}-1/naiveproxy-v${github_version}-1-linux-${arch}.tar.xz
    tar -xf naiveproxy-v${github_version}-1-linux-${arch}.tar.xz
    sleep 5s
    cd naiveproxy-v${github_version}-1-linux-${arch}/
    cp naive /usr/local/bin/
    cd ~
    rm -f /tmp/naiveproxy-v${github_version}-1-linux-${arch}.tar.xz
    rm -rf /tmp/naiveproxy-v${github_version}-1-linux-${arch}/
}

install_naive_client_after(){
    wget -qO /etc/systemd/system/naive.service https://cdn.jsdelivr.net/gh/kwaa/naive.sh@main/naive.service
    mkdir /etc/naive
    while true; do
        read -p "是否要进行配置? [Y/n]" yn
        case $yn in
            [Nn]*) ;;
            *)
                stty erase '^H'
                read -p "设置本地监听 (socks://127.0.0.1:1080): " listen
                read -p "设置远程地址 (https://user:pass@example.com): " proxy
                echo '{"listen": "'${listen}'","proxy": '${proxy}'}' >> /etc/naive/config.json;;
        esac
    done
    systemctl daemon-reload
    systemctl enable naive
    systemctl start naive
}

update_naive_client(){
    if [ "${github_version}" == "${local_version}" ]; then
        echo "本地版本与 GitHub 相同，无需更新。"
    else
        systemctl stop naive
        rm -f /usr/local/bin/naive
        install_naive_client
        systemctl start naive
    fi
}

uninstall_naive_client(){
    systemctl stop naive
    systemctl disable naive
    rm -f /usr/local/bin/naive
    rm -f /etc/systemd/system/naive.service
    rm -rf /etc/naive/
    systemctl daemon-reload
}

install_naive_server_before(){
    if ! [ "$(command -v go)" ]; then
    case "$distro" in
        debian)
            codename=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')
            echo 'deb http://ftp.debian.org/debian '${codename}'-backports main' | tee /etc/apt/sources.list.d/backports.list
            apt update
            apt -t ${codename}-backports install golang-go;;
        ubuntu)
            add-apt-repository ppa:longsleep/golang-backports
            apt update
            apt install golang-go;;
        arch)
            pacman -S go;;
        *)
            echo "暂未支持你使用的发行版，请考虑提交 Pull Request 并自行安装依赖：golang-go"
            exit 0;;
    esac
    fi
}

install_naive_server(){
    cd /tmp
    go get -u github.com/caddyserver/xcaddy/cmd/xcaddy
    ~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
    cp caddy /usr/bin/
    setcap cap_net_bind_service=+ep /usr/bin/caddy
    cd ~
    rm -f /tmp/caddy
}

install_naive_server_after(){
    wget -qO /etc/systemd/system/caddy.service https://cdn.jsdelivr.net/gh/caddyserver/dist@master/init/caddy.service
    mkdir /etc/caddy
    touch /etc/caddy/Caddyfile
    if [ "$1" != "" ]; then
        if [ "$2" == "auto" ]; then
            if [ "$3" != "" ]; then echo -e '{\n  experimental_http3\n}' >> /etc/caddy/Caddyfile; fi
            echo -e ':443, '$1'\ntls tls@'$1'\nroute {\n  forward_proxy {\n    basicauth '$(cat /proc/sys/kernel/random/uuid)' '$(cat /proc/sys/kernel/random/uuid)'\n    hide_ip\n    hide_via\n    probe_resistance '$(cat /proc/sys/kernel/random/uuid)'.com\n  }\n}' >> /etc/caddy/Caddyfile
            sysctl -w net.ipv4.tcp_slow_start_after_idle=0
            sysctl -w net.ipv4.tcp_notsent_lowat=16384
        else
            if [ "$7" != "" ]; then echo -e '{\n  experimental_http3\n}' >> /etc/caddy/Caddyfile; fi
            echo -e ':443, '$1'\ntls '$2'\nroute {\n  forward_proxy {\n    basicauth '$3' '$4'\n    hide_ip\n    hide_via\n    probe_resistance '$5'\n  }' >> /etc/caddy/Caddyfile
            if [[ "$6" != "" || "false" ]]; then echo -e '  reverse_proxy '$6 >> /etc/caddy/Caddyfile; fi
            echo '}' >> /etc/caddy/Caddyfile
        fi
    else
        while true; do
        read -p "是否要进行配置? [Y/n]" yn
        case $yn in
            [Nn]*) ;;
            *)
                stty erase '^H'
                read -p "设置域名 (example.com): " domain
                read -p "设置邮箱 (me@example.com): " email
                read -p "设置用户名称 (user, 为空则自动生成): " user
                if [ "$user" == "" ]; then user=$(cat /proc/sys/kernel/random/uuid); fi
                read -p "设置用户密码 (pass, 为空则自动生成): " pass
                if [ "$pass" == "" ]; then pass=$(cat /proc/sys/kernel/random/uuid); fi
                read -p "设置伪装域名 (probe_resistance, 为空则自动生成): " probe_resistance
                read -p "设置反向代理 (reverse_proxy, 为空则无效): " reverse_proxy
                read -p "是否要开启 HTTP/3? [y/N]:" experimental_http3
                if [[ "$experimental_http3" == "y" || "Y" ]]; then echo -e '{\n  experimental_http3\n}\n' >> /etc/caddy/Caddyfile; fi
                echo -e ':443, '$domain'\ntls '$email'\nroute {\n  forward_proxy {\n    basicauth '$user' '$pass'\n    hide_ip\n    hide_via\n    probe_resistance '$probe_resistance'\n  }\n' >> /etc/caddy/Caddyfile
                if [ "$reverse_proxy" != "" ]; then echo -e '  reverse_proxy '$reverse_proxy'\n' >> /etc/caddy/Caddyfile; fi
                echo '}' >> /etc/caddy/Caddyfile;;
        esac
    done
    fi
    systemctl daemon-reload
    systemctl enable naive
    systemctl start naive
    result_userpass=$(grep -oP '(?<=basicauth )[^"]*' /etc/caddy/Caddyfile | sed 's/ /:/g')
    result_domain=$(grep -oP '(?<=:443, )[^"]*' /etc/caddy/Caddyfile)
    clear
    echo '安装完成！你的代理地址是: '
    grep -q experimental_http3 /etc/caddy/Caddyfile && echo 'quic://'$result_userpass'@'$result_domain || echo 'https://'$result_userpass'@'$result_domain
}

update_naive_server() {
    systemctl stop caddy
    rm -f /usr/bin/caddy
    install_naive_server
    systemctl start caddy
}

uninstall_naive_server() {
    systemctl stop caddy
    systemctl disable caddy
    rm -f /usr/bin/caddy
    rm -f /etc/systemd/system/caddy.service
    rm -rf /etc/caddy/
    systemctl daemon-reload
}

case "$1" in
    u | update)
        if [[ "$2" == "s" || "server" ]]; then
            update_naive_server
        else
            check_naive_client && update_naive_client
        fi
        exit 0;;
    *)
        if [ "$1" != "" ]; then
            function_test "$1" "$2" "$3" "$4" "$5" "$6"
            exit 0
        fi;;
esac

do_option() {
    case "$1" in
        0)
            exit 0
            ;;
        1)
            install_naive_client_before
            install_naive_client
            install_naive_client_after
            exit 0
            ;;
        2)
            uninstall_naive_client
            exit 0
            ;;
        3)
            check_naive_client
            update_naive_client
            exit 0
            ;;
        4)
            install_naive_server_before
            install_naive_server
            install_naive_server_after
            exit 0
            ;;
        5)
            uninstall_naive_server
            exit 0
            ;;
        6)
            update_naive_server
            exit 0
            ;;
        *)
            ;;
    esac
}

check_naive_client

while :
do
    clear
    echo "/* ----------------------------------------------------*"
    echo "* naive.sh  v0.210211                                  *"
    echo "* created by kwaa                                      *"
    echo "* intro: https://kwaa.dev/p/naive-sh                   *"
    echo "* source: https://github.com/kwaa/naive.sh             *"
    echo "* --------------------------------------------------- */"
    echo "最新客户端版本:" ${github_version}
    echo "本地客户端版本:" ${local_version}
    echo "系统类型:" ${distro} ${arch}
while :
do
    echo "0) 退出"
    echo "1) 安装客户端"
    echo "2) 卸载客户端"
    echo "3) 更新客户端"
    echo "4) 安装服务端"
    echo "5) 卸载服务端"
    echo "6) 更新服务端"
    unset choose_an_option
    read -p "输入一个数字: " choose_an_option
    if echo $choose_an_option | grep -qE '^[0-9]+$'; then
        do_option $choose_an_option
        break
    else
        continue
    fi
done
done