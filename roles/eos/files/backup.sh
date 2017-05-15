#!/bin/bash

dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > media-keys
dconf dump /org/gnome/desktop/peripherals/touchpad/ > touchpad
dconf dump /org/gnome/desktop/wm/keybindings/ > keybindings
