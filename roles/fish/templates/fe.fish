function fe
    set cmd $argv[1]

    if test (count $argv) -gt 1;
        set base $argv[2]
    else
        set base "."
    end

    tree -if --noreport $base|fzf > ~/.fcd
    set path (cat ~/.fcd)
    echo $cmd
    echo $base

    if [ $path ]
        eval $cmd $path
    end
end

