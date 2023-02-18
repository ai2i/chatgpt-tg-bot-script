#!/bin/bash
red='\033[0;31m'
bblue='\033[0;34m'
yellow='\033[0;33m'
green='\033[0;32m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}
rred(){ echo -e "\033[35m\033[01m$1\033[0m";}
readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi

start(){
systemctl stop firewalld.service >/dev/null 2>&1
systemctl disable firewalld.service >/dev/null 2>&1
setenforce 0 >/dev/null 2>&1
ufw disable >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -t mangle -F >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -X >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
v4=$(curl -s4m6 ip.sb -k)
if [ -z $v4 ]; then
echo -e nameserver 2a01:4f8:c2c:123f::1 > /etc/resolv.conf
fi
}

chat1(){
[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
$yumapt update
if [[ $release = Centos ]]; then
yum install epel-release -y
[[ ! $(type -P python3-devel) ]] && ($yumapt update;$yumapt install python3-devel python3 -y)
else
[[ ! $(type -P python3-pip) ]] && ($yumapt update;$yumapt install python3-pip -y)
fi
py3=`python3 -V  | awk '{print $2}' | tr -d '.'`
if [[ $py3 -le 370 ]]; then
yellow "检测到python3版本小于3.7.0，现在升级到3.7.3，升级时间比较长，请稍等……" && sleep 3
wget -N https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
tar -zxf Python-3.7.3.tgz
$yumapt install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc libffi-devel make -y
cd Python-3.7.3
./configure --prefix=/usr/local/python3.7
make && make install
co=$(echo $? 2>&1)
if [[ $co = 0 ]]; then
green "升级python3成功"
ln -sf /usr/local/python3.7/bin/python3.7 /usr/bin/python3
else
red "升级python3失败" && exit
fi
fi
pip3 install -U pip
python3 -m pip install openai aiogram 
cat > /root/TGchatgpt.py << EOF
import openai
from aiogram import Bot, types
from aiogram.dispatcher import Dispatcher
from aiogram.utils import executor
token = 'tgtoken'
openai.api_key = 'apikey'
bot = Bot(token)
dp = Dispatcher(bot)
@dp.message_handler()
async def send(message : types.Message):
    response = openai.Completion.create(
    model="text-davinci-003",
    prompt=message.text,
    temperature=0.9,
    max_tokens=1000,
    top_p=1.0,
    frequency_penalty=0.0,
    presence_penalty=0.0,
    stop=["You:"]
)
    await message.answer(response['choices'][0]['text'])
executor.start_polling(dp, skip_updates=True)
EOF
}

chat2(){
readp "输入Telegram的token：" token
sed -i "5 s/tgtoken/$token/" /root/TGchatgpt.py
readp "输入openai的apikey：" key
sed -i "6 s/apikey/$key/" /root/TGchatgpt.py
}

chat3(){
cat << EOF >/lib/systemd/system/Chatgpt.service
[Unit]
Description=ygkkk-Chatgpt Service
After=network.target
[Service]
Restart=on-failure
User=root
ExecStart=/usr/bin/python3 /root/TGchatgpt.py
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable Chatgpt.service
systemctl start Chatgpt.service
systemctl stop Chatgpt.service
systemctl restart Chatgpt.service
green "Chatgpt Telegram机器人安装完毕"
}

chatlog(){
journalctl -u Chatgpt.service
}

stclre(){
if [[ ! -f '/etc/tuic/tuic.json' ]]; then
green "未正常安装tuic" && exit
fi
green "tuic服务执行以下操作"
readp "1. 重启\n2. 关闭\n3. 启动\n请选择：" action
if [[ $action == "1" ]]; then
systemctl restart tuic
green "tuic服务重启\n"
elif [[ $action == "2" ]]; then
systemctl stop tuic
systemctl disable tuic
green "tuic服务关闭\n"
elif [[ $action == "3" ]]; then
systemctl enable tuic
systemctl start tuic
green "tuic服务开启\n"
else
red "输入错误,请重新选择" && stclre
fi
}


changeserv(){
if [[ -z $(systemctl status tuic 2>/dev/null | grep -w active) && ! -f '/etc/tuic/tuic.json' ]]; then
red "未正常安装tuic" && exit
fi
green "tuic配置变更选择如下:"
readp "1. 变更端口\n2. 变更令牌码Token\n3. 重新申请证书或变更证书路径\n4. 返回上层\n请选择：" choose
if [ $choose == "1" ];then
changeport
elif [ $choose == "2" ];then
changepswd
elif [ $choose == "3" ];then
inscertificate
oldcer=`cat /etc/tuic/tuic.json 2>/dev/null | sed -n 4p | awk '{print $2}' | tr -d ',"'`
oldkey=`cat /etc/tuic/tuic.json 2>/dev/null | sed -n 5p | awk '{print $2}' | tr -d ',"'`
sed -i "s#$oldcer#${certificatec}#g" /etc/tuic/tuic.json
sed -i "s#$oldkey#${certificatep}#g" /etc/tuic/tuic.json
oldym=`cat /root/tuic/v2rayn.json 2>/dev/null | sed -n 3p | awk '{print $2}' | tr -d ',"'`
sed -i "s/$oldym/${ym}/g" /root/tuic/v2rayn.json
sed -i "3s/$oldym/${ym}/g" /root/tuic/tuic.txt
susstuic
elif [ $choose == "4" ];then
tu
else 
red "请重新选择" && changeserv
fi
}




unins(){
systemctl stop tuic >/dev/null 2>&1
systemctl disable tuic >/dev/null 2>&1
rm -f /etc/systemd/system/tuic.service
rm -rf /usr/local/bin/tuic /etc/tuic /root/tuic /root/tuic.sh /usr/bin/tu
green "tuic卸载完成！"
}


start_menu(){
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
white "甬哥Github项目  ：github.com/yonggekkk"
white "甬哥blogger博客 ：ygkkk.blogspot.com"
white "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green " 1. 安装hysteria（必选）" 
green " 2. 卸载hysteria"
green " 4. 关闭、开启、重启hysteria"    
green " 6. 更改Telegram的token，"
green " 0. 退出脚本"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
readp "请输入数字:" Input
case "$Input" in     
 1 ) instuic;;
 2 ) unins;;
 3 ) changeserv;;
 4 ) stclre;;
 5 ) uptuicyg;; 
 6 ) uptuic;;
 7 ) tuicshare;;
 8 ) acme;;
 9 ) cfwarp;;
 * ) exit 
esac
}
if [ $# == 0 ]; then
start
start_menu
fi
