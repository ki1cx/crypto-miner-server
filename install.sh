#!/bin/bash
set -e

##======================================
## customize values here accordingly
##======================================
powerDrawTarget=75
temperatureTarget=58
memoryTransferRateTarget=$2
numberOfGPUs=8
minimumHashRate=22
startingFanSpeed=50

projectPath=$(pwd)
claymorePath=/var/lib/claymore-dual-miner

##add-apt-repository
apt-get -y install software-properties-common python-software-properties

##other tools
apt-get -y install build-essential tcpdump lm-sensors wpasupplicant wireless-tools ufw git dkms lshw libcurl3
apt-get -y install python-nfqueue python-scapy

##add a Personal Package Archive (PPA) to the Software Sources
add-apt-repository -y ppa:ethereum/ethereum
add-apt-repository -y ppa:graphics-drivers/ppa
apt-get -y update

##install ethereum
apt-get -y install ethereum geth ethminer

##install nvidia drivers
apt-get -y install nvidia-384 nvidia-settings
apt-get -y install xorg

##make sure server restarts properly when GPU crashes
##system can hang during restart
##https://askubuntu.com/questions/771899/pcie-bus-error-severity-corrected
##http://michalorman.com/2013/10/fix-ubuntu-freeze-during-restart/
sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/c\GRUB_CMDLINE_LINUX_DEFAULT="quiet nosplash pci=noaer reboot=warm,cold,bios,smp,triple,kbd,acpi,efi,pci,force"' /etc/default/grub
update-grub

##use ip4, sometimes ip6 can cause issues
##https://askubuntu.com/questions/574569/apt-get-stuck-at-0-connecting-to-us-archive-ubuntu-com
# uncomment #precedence ::ffff:0:0/96  100
sed -i '/precedence ::ffff:0:0\/96  100/c\precedence ::ffff:0:0\/96  100' /etc/gai.conf


##setup X11
sed -i "/allowed_users=console/c\allowed_users=anybody" /etc/X11/Xwrapper.config
checkNeedsRootRightsEntryCount=$(cat /etc/X11/Xwrapper.config | grep "needs_root_rights=yes" | awk -F ' ' '{print int($2)}' | wc -l)
if [ "$checkNeedsRootRightsEntryCount" -lt "1" ]; then
    echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
fi


##enable GPUs to be configured
nvidia-xconfig --enable-all-gpus -a --allow-empty-initial-configuration --cool-bits=28

##remove and reinstall claymore miner if needed
rm -fr $claymorePath
mkdir -p $claymorePath
cd $claymorePath
wget https://github.com/nanopool/Claymore-Dual-Miner/releases/download/v10.0/Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz
tar -xvf Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz

##setup claymore miner with wallet address
read -ep " please enter your ethereum wallet address: " -i "" ethWalletAddress
epoolsFile=epools.txt
cp $projectPath/templates/$epoolsFile .
sed -i "s@{{eth_wallet_address}}@$ethWalletAddress@g" $epoolsFile

mkdir -p $claymorePath/scripts
cp $projectPath/templates/check.sh $claymorePath/scripts/
cp $projectPath/templates/kill.sh $claymorePath/scripts/
cp $projectPath/templates/mine.sh $claymorePath/scripts/
cp $projectPath/templates/stable.sh $claymorePath/scripts/
cp $projectPath/templates/remove_mining_fees.py $claymorePath/scripts/
cp $projectPath/templates/gpucheck.sh $claymorePath/scripts/

gpuCheckScript=$claymorePath/scripts/gpucheck.sh
sed -i "s@{{powerDrawTarget}}@$powerDrawTarget@g" $gpuCheckScript
sed -i "s@{{temperatureTarget}}@$temperatureTarget@g" $gpuCheckScript
sed -i "s@{{memoryTransferRateTarget}}@$memoryTransferRateTarget@g" $gpuCheckScript
sed -i "s@{{numberOfGPUs}}@$numberOfGPUs@g" $gpuCheckScript
sed -i "s@{{minimumHashRate}}@$minimumHashRate@g" $gpuCheckScript
sed -i "s@{{startingFanSpeed}}@$startingFanSpeed@g" $gpuCheckScript

chmod +x $claymorePath/scripts/*.sh
chmod +x $claymorePath/scripts/*.py

##install cron for monitoring
cronFile=$claymorePath/scripts/crontab
cp $projectPath/templates/crontab $cronFile
sed -i "s@{{claymore_path}}@$claymorePath@g" $cronFile
crontab "$cronFile"

read -p "system needs to restart, restart now?" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo 'restarting...'
  /sbin/shutdown -r now
else
  echo 'please manually restart the system for changes to take effect'
fi
