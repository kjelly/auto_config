function fcd
    if count $argv > /dev/null
        set base $argv
    else
        set base "."
    end

    tree -if --noreport -d $base|fzf > ~/.fcd
    set cd_path (cat ~/.fcd)
    if [ $cd_path ]
        cd $cd_path
    end
end

