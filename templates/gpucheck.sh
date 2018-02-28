#!/bin/bash

powerDrawTarget={{powerDrawTarget}}
temperatureTarget={{temperatureTarget}}
memoryTransferRateTarget={{memoryTransferRateTarget}}
numberOfGPUs={{numberOfGPUs}}
minimumHashRate={{minimumHashRate}}
startingFanSpeed={{startingFanSpeed}}

powerDrawLowerLimit=$((powerDrawTarget-10))
powerDrawUpperLimit=$((powerDrawTarget+10))
lowHashRateCountThreshold=20
cannotConnectCountThreshold=5

claymoreMinerDir=/var/lib/claymore-dual-miner

date
echo ""
echo "numberOfGPUs: $numberOfGPUs"
echo "minimumHashRate: $minimumHashRate"
echo "startingFanSpeed: $startingFanSpeed"
echo "temperatureTarget: $temperatureTarget"
echo "memoryTransferRateTarget: $memoryTransferRateTarget"
echo "powerDrawTarget: $powerDrawTarget"
echo "powerDrawLowerLimit: $powerDrawLowerLimit"
echo "powerDrawUpperLimit: $powerDrawUpperLimit"

XAUTHORITY=$(ps aux | grep [a]uth | awk '{print $17}')
export XAUTHORITY
export DISPLAY=:0

gpuCount=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | wc -l)

if [ "$gpuCount" -ne "$numberOfGPUs" ]; then
  echo "GPU count doesn't match"

	echo "Set proper number of GPUs to detect"

  exit 0
fi

##check for GPU errors
unableToDetermineDevice=$(nvidia-smi | grep "Unable to determine the device handle for" | wc -l)
if [ "$unableToDetermineDevice" -gt "0" ]; then
	echo "Unable to determine the device handle"

	echo "kill miner"
	./kill.sh

	echo "restart the system"
	/sbin/shutdown -r now

  exit 0
fi

##check for usb wireless adapater errors
##reset driver as necessary


wirelesscheckScript=wirelesscheck.sh
if [ -f "$wirelesscheckScript" ]
then
	./$wirelesscheckScript >> wirelesscheck.log
fi

## fresh reboot... wait until miner comes online
pid=$(ps aux | grep ethdcrminer64 | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
	echo "fresh reboot... wait until miner comes online"
	exit 0
fi

## check if gpu check is still running
gpuCheckProcesses=$(ps aux | grep [g]pucheck | awk -F ' ' '{print int($2)}' | wc -l)
if [ "$gpuCheckProcesses" -gt "2" ]; then
    echo "previous gpucheck process still running... exit"

    exit 0
fi

## remove mining fees
pid=$(ps aux | grep remove_mining_fees.py | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
    nohup ./remove_mining_fees.py &
else 
	  logFileSize=$(ls -l remove_mining_fees_log.txt | awk '{print $5}')

    if [ "$logFileSize" = "0" ]; then
      echo "remove mining fee log file size is not right... restart script"

      kill $pid

      nohup ./remove_mining_fees.py &
    fi
fi

## check if all GPUs are still recognized by the OS
gpusFound=$(grep -rn m.log -e "NVIDIA Cards available:" | tail -n 1 | awk -F ':' '{print int($3)}')
if [ "$gpusFound" -lt "$numberOfGPUs" ]; then
	echo "not all gpus identified"

	echo "kill miner"
	./kill.sh

	echo "restart the system"
	/sbin/shutdown -r now

  exit 0
fi

## check if memory overclock is still effective
## check if power consumption is within range
monitorMemoryPower() {
  gpuIndex=0
	while [[ $gpuIndex -lt $gpuCount ]]
	do
    memoryRate=$(nvidia-settings -c :0 -t -q [gpu:$gpuIndex]/GPUMemoryTransferRateOffset)
    powerDraw=$(nvidia-smi -i $gpuIndex -q -d POWER | grep "Power Draw" | awk -F ' ' '{print int($4)}')

    echo "GPU $gpuIndex"
    echo "memoryRate: $memoryRate"
    echo "powerDraw: $powerDraw"

    # for some reason GPU setting have been reset, apply them again
    if [ "$memoryRate" -lt "$memoryTransferRateTarget" ]; then
      echo "for some reason GPU setting have been reset, apply them again"
      ./stable.sh $powerDrawTarget $memoryTransferRateTarget $startingFanSpeed
      exit 0
    fi

    # if power draw is above threshold, then GPU setting have been reset, apply them again
    if [ "$powerDraw" -gt "$powerDrawUpperLimit" ]; then
      echo "for some reason GPU setting have been reset, apply them again"
      ./stable.sh $powerDrawTarget $memoryTransferRateTarget $startingFanSpeed
      exit 0
    fi

    # if power draw is below threshold, then GPU must have errored out and caused the miner to restart
    if [ "$powerDraw" -lt "$powerDrawLowerLimit" ]; then
      echo "GPU must errored out and caused the miner to restart... wait 50 seconds to give miner time to restart"

      #see if miner restarts successfully and resets the GPU
      sleep 50

      powerDraw=$(nvidia-smi -i $gpuIndex -q -d POWER | grep "Power Draw" | awk -F ' ' '{print int($4)}')
      # if power draw is still below, then the miner could not restart. restart the system
      if [ "$powerDraw" -lt "$powerDrawLowerLimit" ]; then
        echo "kill miner"
        ./kill.sh

        echo "miner cannot restart, then restart the system"
        /sbin/shutdown -r now
        exit 0
      fi

    fi

    ((gpuIndex = gpuIndex + 1))

  done
}
monitorMemoryPower


## automatically set fan speed to reach target temperature
monitorTemperature() {

	gpuIndex=0
	while [[ $gpuIndex -lt $gpuCount ]]
	do
	    gpuTemperature=$(nvidia-smi -i $gpuIndex -q -d TEMPERATURE | grep "GPU Current Temp" | awk -F ' ' '{print int($5)}')
      gpuCurrentFanSpeed=$(nvidia-settings -c :0 -t -q [fan:$gpuIndex]/GPUCurrentFanSpeed)
      gpuNewFanSpeed=$gpuCurrentFanSpeed

	    if [ "$gpuTemperature" -gt "$temperatureTarget" ]; then
	    	echo "GPU temp $gpuTemperature > target temp $temperatureTarget... increasing fan speed +1"
	    	gpuNewFanSpeed=$(( gpuCurrentFanSpeed + 1 ))
	   	elif [ "$gpuTemperature" -lt "$temperatureTarget" ]; then
	   		echo "GPU temp $gpuTemperature < target temp $temperatureTarget... decreasing fan speed -1"
	   		gpuNewFanSpeed=$(( gpuCurrentFanSpeed - 1 ))
	    fi

	    if [ "$gpuNewFanSpeed" -gt "100" ]; then
	    	gpuNewFanSpeed=100
	    fi

	    if [ "$gpuNewFanSpeed" -ne "$gpuCurrentFanSpeed" ]; then
	    	nvidia-settings -c :0 -a [gpu:$gpuIndex]/GPUFanControlState=1 -a [fan:$gpuIndex]/GPUTargetFanSpeed=$gpuNewFanSpeed
		  fi

      ((gpuIndex = gpuIndex + 1))
	done

}
monitorTemperature


## check for irregular hashrate
## if low, then restart
lowHashRateCount=$(grep -rn m.log -e "GPU. $minimumHashRate" | wc -l)
if [ "$lowHashRateCount" -gt "$lowHashRateCountThreshold" ]; then
	echo "hashrate is not optimal, instead of applying GPU settings again (which could get stuck), restart the server"

	echo "kill miner"
	./kill.sh

	echo "restart the system"
	/sbin/shutdown -r now

  exit 0
fi

## check for miner connection issues
logFile=$(ls $claymoreMinerDir/*log.txt| tail -1)
cannotConnectCount=$(grep -r $logFile -ne "ETH: Stratum - Cannot connect to" | wc -l)
echo $logFile
if [ "$cannotConnectCount" -gt "$cannotConnectCountThreshold" ]; then
	echo "ETH: Stratum - Cannot connect to pool"
	echo "kill miner"
	./kill.sh

	echo "restart the system"
	/sbin/shutdown -r now

	exit 0
fi

echo "everything is ok"


