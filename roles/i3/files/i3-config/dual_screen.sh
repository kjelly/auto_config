#! /usr/bin/env bash
screen1="DVI-I-0"
screen2="DP-0"
xrandr --output $screen1 --mode 1920x1080
xrandr --output $screen2 --mode 1440x900
xrandr --output $screen2 --left-of $screen1
#xrandr --output $screen1 --primary
feh --bg-scale ~/Pictures/background.jpg

