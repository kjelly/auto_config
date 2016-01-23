#!/bin/bash
s=$1
fileName=${s##*/}
basename=${fileName%.*}
ebook-convert $1 "$basename".epub  --enable-heuristics
