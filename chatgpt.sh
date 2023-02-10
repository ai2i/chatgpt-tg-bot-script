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
#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts
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
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。" && rm -f CFwarp.sh && exit
fi

[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
[[ $(type -P curl) ]] || (yellow "检测到curl未安装，升级安装中" && $yumapt update;$yumapt install curl)
[[ ! $(type -P python3) ]] && (yellow "检测到python3未安装，升级安装中" && $yumapt update;$yumapt install python3)
[[ ! $(type -P screen) ]] && (yellow "检测到screen未安装，升级安装中" && $yumapt update;$yumapt install screen)

apt update && pip install -U pip && pip install openai aiogram 

cat > TGchatgpt.py << EOF
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
    presence_penalty=0.6,
    stop=["You:"]
)
    await message.answer(response['choices'][0]['text'])

executor.start_polling(dp, skip_updates=True)
EOF

readp "输入Telegram的token：" token
sed -i "6 s/tgtoken/'$token'/" TGchatgpt.py
readp "输入openai的apikey：" key
sed -i "7 s/apikey/'$key'/" TGchatgpt.py
python3 TGchatgpt.py
[[ -e /root/TGchatgpt.py ]] && screen -S chatgpt -X quit ; screen -UdmS chatgpt /usr/bin/python3 /root/TGchatgpt.py'
green "设置screen窗口名称'chatgpt'" && sleep 2
grep -qE "^ *@reboot root screen -UdmS chatgpt /usr/bin/python3 /root/TGchatgpt.py >/dev/null 2>&1" /etc/crontab || echo "@reboot root screen -UdmS chatgpt /usr/bin/python3 /root/TGchatgpt.py >/dev/null 2>&1" >> /etc/crontab
green "添加chatgpt在线守护进程功能"




