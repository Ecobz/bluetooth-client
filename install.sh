#!/bin/bash

echo "   ___  _             _                                          "
echo "  / __\| |__   _   _ | |  __ _                                   "
echo " / /   | '_ \ | | | || | / _\` |                                  "
echo "/ /___ | | | || |_| || || (_| |                                  "
echo "\____/ |_| |_| \__,_||_| \__,_|                                  "
echo "                                                                 "
echo "   ___  _               _                  _    _                "
echo "  / __\| | _   _   ___ | |_   ___    ___  | |_ | |__             "
echo " /__\//| || | | | / _ \| __| / _ \  / _ \ | __|| '_ \            "
echo "/ \/  \| || |_| ||  __/| |_ | (_) || (_) || |_ | | | |           "
echo "\_____/|_| \__,_| \___| \__| \___/  \___/  \__||_| |_|           "
echo "                                                                 "
echo " _                                                               "
echo "| |__   _   _                                                    "
echo "| '_ \ | | | |                                                   "
echo "| |_) || |_| |                                                   "
echo "|_.__/  \__, |                                                   "
echo "        |___/                                                    "
echo "   _    _                      _  _    _                 _       "
echo "  /_\  | |  __ _   ___   _ __ (_)| |_ | |__   _ __ ___  (_)  ___ "
echo " //_\\ | | / _\` | / _ \ | '__|| || __|| '_ \ | '_ \` _ \ | | / __|"
echo "/  _  \| || (_| || (_) || |   | || |_ | | | || | | | | || || (__ "
echo "\_/ \_/|_| \__, | \___/ |_|   |_| \__||_| |_||_| |_| |_||_| \___|"
echo "           |___/                                                 "
echo "   _____                                                         "
echo "   \_   \ _ __    ___                                            "
echo "    / /\/| '_ \  / __|                                           "
echo " /\/ /_  | | | || (__  _                                         "
echo " \____/  |_| |_| \___|(_)                                        "
echo "                                                                 "
echo "                                                                 "
echo "                                                                 "
echo "                                                                 "
echo "                                                                 "
echo "                                                                 "
echo "                                                                 "
echo ""
echo "--------------------------------------"
echo "Welcome to Chula Bluetooth scan client"
echo "--------------------------------------"
echo ""

echo "Your RaspberryPi device id : "
read deviceid

echo "Is connect to Industial 4G Router? (y/n)"
read is_industialrouter

echo "Install Shellhub? (y/n)"
read is_shellhub

echo "deb http://mirror.nus.edu.sg/raspbian/raspbian buster main contrib non-free rpi" > /etc/apt/sources.list
cat /etc/apt/sources.list

apt-get update -y
echo "Installing DOCKER ..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

apt-get dist-upgrade -y
apt-get install -y bluez python-bluez python-pip screen
pip install requests

systemctl enable ssh
timedatectl set-timezone Asia/Bangkok
timedatectl set-ntp true
#apt-get install -y ntpdate
#ntpd -gq

mkdir /srv/bt_monitor
mkdir /srv/bt_monitor/save
mkdir /srv/bt_monitor/log
cd /srv/bt_monitor

echo $deviceid >> id.txt
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/bluetooth_scan.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/bluetooth_scan_offline.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/async_datasend.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/check_internet.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/device_active.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/reboot_mr3020.py
curl -O https://raw.githubusercontent.com/BluSense/bluetooth-client/master/change_id.sh
chmod +x change_id.sh

(crontab -u root -l; echo "@reboot /bin/sleep 180 ; /usr/bin/python /srv/bt_monitor/bluetooth_scan_offline.py ; /sbin/reboot" ) | crontab -u root -
(crontab -u root -l; echo "*/1 * * * * /usr/bin/python /srv/bt_monitor/async_datasend.py" ) | crontab -u root -
(crontab -u root -l; echo "*/1 * * * * /usr/bin/python /srv/bt_monitor/device_active.py" ) | crontab -u root -
if [ $is_industialrouter = n ]; then
	(crontab -u root -l; echo "*/4 * * * * /usr/bin/python /srv/bt_monitor/check_internet.py" ) | crontab -u root -
	(crontab -u root -l; echo "0 2 * * * /usr/bin/python /srv/bt_monitor/reboot_mr3020.py" ) | crontab -u root -
fi
(crontab -u root -l; echo "0 3 * * * /sbin/reboot" ) | crontab -u root -

echo "Configuring hostname..."

echo $deviceid | tee /etc/hostname

sed -i '$d' /etc/hosts
printf "127.0.0.1\t$deviceid\n" | tee --append /etc/hosts
hostnamectl set-hostname $deviceid
systemctl restart avahi-daemon

if [ $is_shellhub = y ]; then
	echo "Shellhub will now be installed CALL the following command..."
	INSTALL_URL="sh <(curl -Ss http://shellhub.blusense.co/install.sh?tenant_id=db1bdec8-fae7-4f8b-8556-2da8bf8f4d14&preferred_hostname=$deviceid&keepalive_interval=5)"
	echo "$INSTALL_URL"

	docker run -d \
	       --name=shellhub \
	       --restart=on-failure \
	       --privileged \
	       --net=host \
	       --pid=host \
	       -v /:/host \
	       -v /dev:/dev \
	       -v /var/run/docker.sock:/var/run/docker.sock \
	       -v /etc/passwd:/etc/passwd \
	       -v /etc/group:/etc/group \
	       -v /etc/resolv.conf:/etc/resolv.conf \
	       -v /var/run:/var/run \
	       -v /var/log:/var/log \
	       -e SHELLHUB_SERVER_ADDRESS=http://shellhub.blusense.co \
	       -e SHELLHUB_PRIVATE_KEY=/host/etc/shellhub.key \
	       -e SHELLHUB_TENANT_ID=db1bdec8-fae7-4f8b-8556-2da8bf8f4d14 \
	       -e SHELLHUB_KEEPALIVE_INTERVAL=5 \
	       -e SHELLHUB_PREFERRED_HOSTNAME=$deviceid \
	       shellhubio/agent:v0.7.3
fi

echo "   ___  _         _       _     "
echo "  / __\(_) _ __  (_) ___ | |__  "
echo " / _\  | || '_ \ | |/ __|| '_ \ "
echo "/ /    | || | | || |\__ \| | | |"
echo "\/     |_||_| |_||_||___/|_| |_|"
echo "                                "

echo "Finish install Bluetooth Sensor "
echo "Reboot ? (y/n) :"
read isreboot

if [ $isreboot = y ]; then
	reboot
fi
