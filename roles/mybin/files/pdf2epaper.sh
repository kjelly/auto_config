#!/bin/bash

k2pdfopt -as -dev kpw -fc 50.pdf -w 560 -h 745 -dpi 167 -idpi -2 -w 1404 -h 1872 -dpi 227 -idpi -2 $@
