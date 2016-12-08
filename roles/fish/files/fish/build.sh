rm get_color
rm get_host_color
rm print_cwd

chmod +x get_color.py get_host_color.py print_cwd.py

if [ $# -eq 0 ]
then
    go build get_color.go
    go build get_host_color.go
    go build print_cwd.go
else
    ln -s get_color.py get_color
    ln -s get_host_color.py get_host_color
    ln -s print_cwd.py print_cwd
fi

