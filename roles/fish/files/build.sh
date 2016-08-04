#!/bin/bash

rm -f print_cwd
rm -f get_color
rm -f get_host_color

go build print_cwd.go
go build get_color.go
go build get_host_color.go
