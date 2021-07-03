#!/bin/bash

total_stdy="$(($(stty size|cut -d' ' -f1)))"
total_stdx="$(($(stty size|cut -d' ' -f2)))"

head="Progress bar: "
total=$[${total_stdx} - ${#head}*2]

i=0
loop=100
while [ $i -lt $loop ]
do
    let i=i+5
    
    per=$[${i}*${total}/${loop}]
    remain=$[${total} - ${per}]
    printf "\r\e[${total_stdy};0H${head}\e[42m%${per}s\e[47m%${remain}s\e[00m" "" ""
    sleep 0.1
done

echo "start"

echo -e "\033[1;31m 脚本开始运行(由Jacob D制作) \033[0m"

sleep 3

echo -e "\033[1;32m 开始安装 iptables \033[0m"

apt-get -y install iptables

echo -e "\033[1;34m iptables安装完成 \033[0m"

echo -e "\033[1;32m 开始安装 iptables-services \033[0m"

apt-get -y install iptables-services

echo -e "\033[1;34m iptables-services安装完成 \033[0m"

echo -e "\033[1;32m 停止firewalld服务 \033[0m"

systemctl stop firewalld

echo -e "\033[1;34m 已停止firewalld服务 \033[0m"

echo -e "\033[1;32m 禁用firewalld服务 \033[0m"

systemctl mask firewalld

echo -e "\033[1;34m 已禁用firewalld服务 \033[0m"

echo -e "\033[1;32m 开始制作iptables脚本 \033[0m"

mkdir bin

cd bin && rm -rf iptables.sh*

echo > iptables.sh

#! /bin/bash
cat>/root/bin/iptables.sh<<EOF
#!/bin/sh
iptables -P INPUT ACCEPT
iptables -F
iptables -X
iptables -Z
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 8090 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 8090 -j ACCEPT
iptables -A INPUT -p tcp --dport 1082 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1082 -j ACCEPT
iptables -A INPUT -p tcp --dport 1:65535 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1:65535 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
service iptables save
systemctl restart iptables.service
systemctl enable iptables.service
EOF

chmod +x iptables.sh && ./iptables.sh

cd

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+5
    str+=">"
done
echo "loading"

echo -e "\033[1;32m 开始同步时间 \033[0m"

echo -e "\033[1;32m 查看时区 \033[0m"

timedatectl status|grep 'Time zone'

echo -e "\033[1;32m 设置硬件时钟调整为与本地时钟一致 \033[0m"

timedatectl set-local-rtc 1

echo -e "\033[1;34m 已设置硬件时钟调整为与本地时钟一致 \033[0m"

echo -e "\033[1;32m 设置时区为上海 \033[0m"

timedatectl set-timezone Asia/Shanghai

echo -e "\033[1;34m 已设置时区为上海 \033[0m"

echo -e "\033[1;32m 安装ntpdate \033[0m"

apt-get -y install ntpdate

echo -e "\033[1;34m 已安装ntpdate \033[0m"

echo -e "\033[1;32m 同步时间 \033[0m"

ntpdate -u pool.ntp.org

echo -e "\033[1;34m 已同步时间 \033[0m"

echo -e "\033[1;32m 查看时间 \033[0m"
date

echo -e "\033[1;32m 查看路径 \033[0m"

which ntpdate

echo -e "\033[1;32m 开始配置定时任务 \033[0m"

sed -i 's/.*ntpdate.*//' /var/spool/cron/root

echo > /var/spool/cron/root  && echo '*/1 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1' | cat - /var/spool/cron/root > temp && echo y | mv temp /var/spool/cron/root && service crond reload

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+5
    str+=">"
done
echo "loading"

echo -e "\033[1;31m 开始卸载docker \033[0m"

docker kill $(docker ps -a -q)

docker rm $(docker ps -a -q)

docker rmi $(docker images -q)

systemctl stop docker

rm -rf /etc/docker

rm -rf /run/docker

rm -rf /var/lib/dockershim

rm -rf /var/lib/docker

umount /var/lib/docker/devicemapper

apt-get list installed | grep docker

apt-get remove docker-engine docker-engine-selinux.noarch

echo -e "\033[1;31m 开始卸载docker-compose \033[0m"

sudo rm /usr/local/bin/docker-compose

echo -e "\033[1;32m 开始安装docker \033[0m"

curl -fsSL http://www.jacobsdocuments.xyz/Code/docker/get.docker.com.sh | bash

echo -e "\033[1;32m 开始安装docker-compose \033[0m"

curl -L "http://www.jacobsdocuments.xyz/Code/docker/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose

chmod a+x /usr/local/bin/docker-compose

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

rm -f which dc

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

ln -s /usr/local/bin/docker-compose /usr/bin/dc

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

systemctl start docker

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

service docker start

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

systemctl enable docker.service

#!/bin/bash
i=0
str=""
arry=("|" "/" "-" "\\")
while [ $i -le 100 ]
do
    let index=i%4
    printf "%3d%% %c%-20s%c\r" "$i" "${arry[$index]}" "$str" "${arry[$index]}"
    sleep 0.2
    let i=i+10
    str+=">"
done
echo "done"

echo -e "\033[1;34m OK \033[0m"

echo -e "\033[1;31m 开始卸载v2ray \033[0m"

systemctl stop v2ray

systemctl disable v2ray

service v2ray stop

update-rc.d -f v2ray remove

rm -rf /etc/v2ray/*

rm -rf /usr/bin/v2ray/*

rm -rf /var/log/v2ray/*

rm -rf /lib/systemd/system/v2ray.service

rm -rf /etc/init.d/v2ray

echo -e "\033[1;32m 开始安装v2ray \033[0m"

rm -rf /etc/v2ray/config.json* && rm -rf install-release.sh* && wget http://www.jacobsdocuments.xyz/Code/v2ray/install-release.sh;bash install-release.sh && service v2ray restart && cat /etc/v2ray/config.json && history -c && history -w

echo -e "\033[1;32m 开始获取后端 \033[0m"

apt-get install -y git 2> /dev/null || apt install -y git

#!/bin/bash
i=0
str=""
arry=("\\" "|" "/" "-")
while [ $i -le 100 ]
do
    let index=i%4
    printf "[%-100s] %d %c\r" "$str" "$i" "${arry[$index]}"
    sleep 0.1
    let i=i+1
    str+="#"
done
echo "done"

echo -e "\033[1;32m 开始下载后端文件(先输入1或2最后输入0) \033[0m"

#!/bin/sh
until
        echo "1.国外机专用"
        echo "2.国内机专用"
                        echo "0.退出菜单"
        read input
        test $input = 0
        do
            case $input in
            1)rm -rf v2ray-poseidon* && wget http://www.jacobsdocuments.xyz/v2ray-poseidon/v2ray-poseidon.tar.gz && tar zxvf v2ray-poseidon.tar.gz && rm -rf v2ray-poseidon.tar.gz*;;
            2)rm -rf v2ray-poseidon-cn* && wget http://www.jacobsdocuments.xyz/v2ray-poseidon/v2ray-poseidon-cn.tar.gz && tar zxvf v2ray-poseidon-cn.tar.gz && rm -rf v2ray-poseidon-cn.tar.gz*;;
            0)echo "请输入选择（1-3）"
            esac
            done

echo -e "\033[1;34m All Done \033[0m"
