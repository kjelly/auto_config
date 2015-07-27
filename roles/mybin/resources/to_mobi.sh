s=$1
fileName=${s##*/}
basename=${fileName%.*}
ebook-convert $1 .mobi  --enable-heuristics
