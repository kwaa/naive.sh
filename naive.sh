#!/usr/bin/env bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

if [ $(id -u) != "0" ]; then
    echo "你必须要以 root 身份运行此脚本！"
    exit 1
fi

if [ $(uname -m)='x86_64' ];then
    arch="x64"
else
    arch="x86"
fi

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

install_naive_after(){
    wget --no-check-certificate -qO /etc/systemd/system/naive.service https://raw.githubusercontent.com/kwaa/naive.sh/master/naive.service
    mkdir /etc/naive
    read -p "设置监听端口: " port
    echo '{"listen": "http://127.0.0.1:'${port}'","padding": true}' >> /etc/naive/config.json
    systemctl daemon-reload
    systemctl enable naive
    systemctl start naive
}

install_naive(){
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

update_naive(){
    if [ "${github_version}" == "${local_version}" ]; then
        echo "本地版本与 GitHub 相同，无需更新。"
    else
        systemctl stop naive
        rm -f /usr/local/bin/naive
        install_naive
        systemctl start naive
    fi
}

uninstall_naive(){
    systemctl disable naive
    systemctl stop naive
    rm -f /usr/local/bin/naive
    rm -f /etc/systemd/system/naive.service
    rm -rf /etc/naive/
    systemctl daemon-reload
}

[[ "$1" = "update" ]] && update_naive && exit 0

do_option() {
    case "$1" in
        0)
            exit 0
            ;;
        1)
            install_naive
            install_naive_after
            exit 0
            ;;
        2)
            uninstall_naive
            exit 0
            ;;
        3)
            update_naive
            exit 0
            ;;
        4)
            port_test
            exit 0
            ;;
    esac
}

while :
do
    clear
    echo "/* ----------------------------------------------------*"
    echo "* naive.sh  v0.200909                                  *"
    echo "* created by kwaa                                      *"
    echo "* intro: https://kwaa.dev/naive-sh                     *"
    echo "* source: https://github.com/kwaa/naive.sh             *"
    echo "* --------------------------------------------------- */"
    echo "最新版本:" ${github_version}
    echo "本地版本:" ${local_version}
while :
do
    echo "0) 退出脚本"
    echo "1) 安装 NaiveProxy"
    echo "2) 卸载 NaiveProxy"
    echo "3) 更新 Naiveproxy"
    unset choose_an_option
    read -p "输入一个数字: " choose_an_option
    if [[ "$choose_an_option" = "0" ]] || [[ "$choose_an_option" = "1" ]] || [[ "$choose_an_option" = "2" ]] || [[ "$choose_an_option" = "3" ]]; then
        do_option $choose_an_option
        break
    else
        continue
    fi
done
done