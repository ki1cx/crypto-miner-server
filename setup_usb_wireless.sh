#!/bin/sh

projectPath=$(pwd)

cd /var/lib
git clone https://github.com/diederikdehaas/rtl8812AU.git
cd rtl8812AU

##install usb wifi driver
apt-get -y install dkms
DRV_NAME=rtl8812AU
DRV_VERSION=4.3.14
mkdir /usr/src/${DRV_NAME}-${DRV_VERSION}
git archive driver-${DRV_VERSION} | tar -x -C /usr/src/${DRV_NAME}-${DRV_VERSION}
dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
modprobe -a 8812au

##get wireless name
wirelessLogicalName=$(lshw -C network -short | grep Wireless | awk '{print $2}')

##ask for wifi network info
read -ep " please enter your wifi network ssid: " -i "" ssid
read -ep " please enter your wifi network password: " -i "" password

##add usb wifi device to interfaces file
echo "" >> /etc/network/interfaces
cat <<EOT >> /etc/network/interfaces
#usb wifi
auto $wirelessLogicalName
allow-hotplug $wirelessLogicalName
iface $wirelessLogicalName inet dhcp
wpa-ssid $ssid
wpa-psk $password
wireless-power off
EOT

##reduce wait time for start job is running for raise network interfaces
sed -i '/TimeoutStartSec/c\TimeoutStartSec=10sec' /etc/systemd/system/network-online.target.wants/networking.service
sed -i '/TimeoutStartSec/c\TimeoutStartSec=10sec' /lib/systemd/system/networking.service

##wireless device check script
cp $projectPath/templates/wirelesscheck.sh $projectPath/scripts/wirelesscheck.sh
sed -i "s@{{wirelessLogicalName}}@$wirelessLogicalName@g" $projectPath/scripts/wirelesscheck.sh

echo "Disconnect ethernet cable before turning the system back on"

##shutdown
shutdown -h now