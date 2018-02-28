#!/bin/bash
set -e

pid=$(ps aux | grep remove_mining_fees.py | grep -v grep | awk '{print $2}')

XAUTHORITY=$(ps aux | grep [a]uth | awk '{print $17}')
export XAUTHORITY
export DISPLAY=:0

##verify nvidia tools can detect the gpus
nvidia-settings -c :0 -q gpus
nvidia-smi