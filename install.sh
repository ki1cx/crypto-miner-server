#!/bin/bash
set -e

projectPath=$(pwd)

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
echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config

##enable GPUs to be configured
nvidia-xconfig --enable-all-gpus -a --allow-empty-initial-configuration --cool-bits=28

##install claymore miner
mkdir -p /var/lib/claymore-dual-miner
cd /var/lib/claymore-dual-miner
wget https://github.com/nanopool/Claymore-Dual-Miner/releases/download/v10.0/Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz
tar -xvf Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.0.-.LINUX.tar.gz

##setup claymore miner with wallet address
read -ep " please enter your ethereum wallet address: " -i "" ethWalletAddress
epoolsFile=epools.txt
cp $projectPath/templates/$epoolsFile .
sed -i "s@{{eth_wallet_address}}@$ethWalletAddress@g" $epoolsFile

mkdir -p $projectPath/scripts
cp $projectPath/check.sh $projectPath/scripts/
cp $projectPath/gpucheck.sh $projectPath/scripts/
cp $projectPath/kill.sh $projectPath/scripts/
cp $projectPath/mine.sh $projectPath/scripts/
cp $projectPath/stable.sh $projectPath/scripts/
cp $projectPath/remove_mining_fees.py $projectPath/scripts/

##install cron for monitoring
cronFile=$projectPath/crontab
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
