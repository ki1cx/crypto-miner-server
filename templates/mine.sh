#!/bin/sh

export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

# start low
nvidia-smi -pm 1
nvidia-smi -pl 60

nohup ../ethdcrminer64 -ftime 3 -esm 0 -ejobtimeout 1 -erate 0 -epsw x -mode 1 -tt 68 > m.log &

