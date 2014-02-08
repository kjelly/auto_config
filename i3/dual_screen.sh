#! /usr/bin/env bash
xrandr --output VGA1 --mode 1920x1080
xrandr --output LVDS1 --mode 1366x768
xrandr --output LVDS1 --right-of VGA1
feh --bg-scale ~/Picture/background.jpg

