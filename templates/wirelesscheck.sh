#!/bin/bash

wirelessLogicalName={{wirelessLogicalName}}

ifconfig $wirelessLogicalName

if [ "$?" = "1" ]; then
	echo "wifi not good... reinstall"

	echo "kill miner"
    ./kill.sh

	cd /var/lib/rtl8812AU

	DRV_NAME=rtl8812AU
	DRV_VERSION=4.3.14
	dkms remove ${DRV_NAME}/${DRV_VERSION} --all
	dkms install -m ${DRV_NAME} -v ${DRV_VERSION}

	modprobe -a 8812au

	shutdown -r now

else
	echo "wifi good"
fi