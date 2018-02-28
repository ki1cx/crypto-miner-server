#!/bin/sh

pkill -f ethdcrminer64
pkill -f mine.sh
ps aux | grep ethdcrminer64
ps aux | grep mine.sh

pkill -f remove_mining_fees.py
ps aux | grep remove_mining_fees.py