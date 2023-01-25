#!/bin/bash
current=$(cat /sys/class/backlight/intel_backlight/brightness)
max=$(cat /sys/class/backlight/intel_backlight/max_brightness)
per=$((current*100/max))
if [ "$1" = "+" ];then
    new=$((per+5))
    if [ $new -gt 100 ];then
        new=$max
    fi
    echo $((new*max/100)) |sudo tee /sys/class/backlight/intel_backlight/brightness
elif [ "$1" = "-" ];then
    new=$((per-5))
    if [ $new -lt 0 ];then
        new=0
    fi
    echo $((new*max/100)) |sudo tee /sys/class/backlight/intel_backlight/brightness
else
    if [ $per -eq 100 ];then
        echo "$per%"
    elif [ $per -gt 75 ];then
        echo "$per%"
    elif [ $per -gt 50 ];then
        echo "$per%"
    elif [ $per -gt 25 ];then
        echo "$per%"
    else
        echo "$per%"
    fi
fi
