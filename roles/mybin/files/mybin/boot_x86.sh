#! /usr/bin/env bash
qemu-system-i386 -machine accel=kvm -m 1024 -vga std -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic -monitor telnet:127.0.0.1:1234,server,nowait -usbdevice tablet "$@"
