function fvi
    if test (count $argv) -gt 0;
        set base $argv[1]
    else
        set base "."
    end

    tree -if --noreport $base|fzf > ~/.fcd
    set path (cat ~/.fcd)
    echo $base

    if [ $path ]
        eval myvi $path
    end

end
