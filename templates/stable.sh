#!/bin/bash

powerDrawTarget=$1
memoryTransferRateTarget=$2
startingFanSpeed=$3

nvidia-smi -pm 1
nvidia-smi -pl $powerDrawTarget

XAUTHORITY=$(ps aux | grep [a]uth | awk '{print $17}')
export XAUTHORITY
export DISPLAY=:0

nvidia-settings -c :0 -a GPULogoBrightness=0
nvidia-settings -c :0 -a GpuPowerMizerMode=1
nvidia-settings -c :0 -a GPUGraphicsClockOffset[3]=0
nvidia-settings -c :0 -a GPUMemoryTransferRateOffset[3]=$memoryTransferRateTarget

## set starting fan speed across all GPUs
nvidia-settings -c :0 -a GPUFanControlState=1 -a GPUTargetFanSpeed=$startingFanSpeed

## control fan speed for specific GPU
#nvidia-settings -c :0 -a [gpu:0]/GPUFanControlState=1 -a [fan:0]/GPUTargetFanSpeed=100
#nvidia-settings -c :0 -a [gpu:6]/GPUFanControlState=1 -a [fan:6]/GPUTargetFanSpeed=100