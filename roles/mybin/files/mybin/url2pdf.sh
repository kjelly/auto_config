#!/bin/bash

ssh vm curl "'$1'" > /tmp/a.html
name=`nokogiri -e 'puts $_.at_css("title").content' /tmp/a.html`
name=`echo $name|tr " " "_"`
echo $name
htmldoc --webpage -f "$name".pdf /tmp/a.html
