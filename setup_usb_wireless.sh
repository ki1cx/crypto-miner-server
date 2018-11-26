#!/bin/bash

projectPath=$(pwd)
claymorePath=/var/lib/claymore-dual-miner
wifiDriverPath=/var/lib/rtl8812AU

if [ -d "$wifiDriverPath" ]; then
  echo "already cloned"
else
  cd /var/lib
  git clone -b driver-4.3.14 https://github.com/diederikdehaas/rtl8812AU.git
fi

cd $wifiDriverPath

##install usb wifi driver
apt-get -y install dkms
DRV_NAME=rtl8812AU
DRV_VERSION=4.3.14
mkdir -p /usr/src/${DRV_NAME}-${DRV_VERSION}
git archive driver-${DRV_VERSION} | tar -x -C /usr/src/${DRV_NAME}-${DRV_VERSION}
dkms remove ${DRV_NAME}/${DRV_VERSION} --all
dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
modprobe -a 8812au

##get wireless name
wirelessLogicalName=$(lshw -C network -short | grep Wireless | awk '{print $2}')

wirelessEntry=$(grep -rn /etc/network/interfaces -e "$wirelessLogicalName" | wc -l)
if [ "$wirelessEntry" -gt "0" ]; then
  echo "wireless entry already exists"

else

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

fi


##reduce wait time for start job is running for raise network interfaces
sed -i '/TimeoutStartSec/c\TimeoutStartSec=10sec' /etc/systemd/system/network-online.target.wants/networking.service
sed -i '/TimeoutStartSec/c\TimeoutStartSec=10sec' /lib/systemd/system/networking.service

##wireless device check script
cp $projectPath/templates/wirelesscheck.sh $claymorePath/scripts/wirelesscheck.sh
sed -i "s@{{wirelessLogicalName}}@$wirelessLogicalName@g" $claymorePath/scripts/wirelesscheck.sh

echo "Disconnect ethernet cable before turning the system back on"

##shutdown
shutdown -h now
