echo "wrod: $1"
w3m http://tw.dictionary.yahoo.com/dictionary?p=$1 |grep "[0-9]\+\. \| KK\[.*\]"
